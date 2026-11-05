import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/date_key.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

// Day snapshot copies keep only what belongs to the day; the habit's own
// details (notes, reminders, translated names, streaks, pause history) stay
// on the habit and are filled in from it when a past day is shown.

DateTime _n(DateTime d) => DateTime(d.year, d.month, d.day);
String _k(DateTime d) => _n(d).toIso8601String().split('T').first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('day_snapshot_slim');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    Hive.registerAdapter(ScheduleTypeAdapter());
    Hive.registerAdapter(PremadeHabitTypeAdapter());
    Hive.registerAdapter(HabitTrackingTypeAdapter());
    Hive.registerAdapter(HabitNotificationTimeAdapter());
    Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
    habitBox = await Hive.openBox<Habit>('habits');
    daysBox = await Hive.openBox<Day>('days');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  final today = _n(DateTime.now());
  DateTime ago(int days) => addCalendarDays(today, -days);
  final stamp = DateTime.utc(2026, 5, 1);

  Habit full() => buildTestHabit(
    id: 1,
    name: 'read',
    trackingType: null,
    createdAt: ago(30),
    timestamps: {
      'description': stamp,
      'notificationTimes': stamp,
      'localizedNames': stamp,
      'optional': stamp,
    },
  )
    ..description = 'ten pages'
    ..localizedNames = {'hr': 'čitanje'}
    ..notificationsEnabled = true
    ..notificationTimes = [HabitNotificationTime(id: 1, minutesOfDay: 600)]
    ..soundKey = 'chime'
    ..isAlarm = true
    ..streak = 7
    ..longestStreak = 12
    ..insightPopstonedUntil = stamp
    ..pausedRanges = [stamp, stamp.add(const Duration(days: 2))]
    ..optional = true;

  Future<void> boot(List<Habit> habits, {Map<String, Object> prefs = const {}})
      async {
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _k(today),
      'daySnapshotsSanitized_v1': true,
      ...prefs,
    });
    await habitBox.clear();
    await daysBox.clear();
    for (final h in habits) {
      await habitBox.add(h);
    }
  }

  Future<HabitProvider> startProvider() async {
    final p = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!p.isInitialized) {
      if (DateTime.now().isAfter(deadline)) fail('HabitProvider.init timed out');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return p;
  }

  test('a day copy drops the habit-only fields and keeps the rest', () {
    final h = full()..completed = true;
    final c = h.forDay();
    expect(c.hasHabitOnlyFields, isFalse);
    // notes stay with the day
    expect(c.description, 'ten pages');
    expect(c.localizedNames, isEmpty);
    expect(c.notificationTimes, isEmpty);
    expect(c.streak, 0);
    expect(c.pausedRanges, isEmpty);
    expect(
      c.timestamps.keys,
      unorderedEquals(['optional', 'createdAt', 'description']),
    );
    // the day's own data stays
    expect(c.completed, isTrue);
    expect(c.optional, isTrue);
    expect(c.name, 'read');
    // the habit itself is untouched
    expect(h.hasHabitOnlyFields, isTrue);
    expect(h.notificationTimes, hasLength(1));
  });

  test('a day serializes without them and reads back', () {
    final day = Day(date: ago(1), habits: [full()], timestamp: stamp);
    final map = day.toMap();
    final habitMap = (map['habits'] as List).single as Map<String, dynamic>;
    expect(habitMap['description'], 'ten pages');
    for (final key in [
      'localizedNames',
      'notificationTimes',
      'notificationsEnabled',
      'soundKey',
      'isAlarm',
      'streak',
      'longestStreak',
      'insightPopstonedUntil',
      'deletedAt',
      'pausedRanges',
    ]) {
      expect(habitMap.containsKey(key), isFalse, reason: key);
    }
    expect(
      (habitMap['timestamps'] as Map).keys,
      unorderedEquals(['optional', 'createdAt', 'description']),
    );
    // what an older app version needs to read the copy is still there
    final read = Day.fromMap(map).habits.single;
    expect(read.name, 'read');
    expect(read.optional, isTrue);
    // the full habit record keeps everything
    expect(full().toMap()['localizedNames'], {'hr': 'čitanje'});
  });

  test('existing days are slimmed once, without touching their timestamp',
      () async {
    await boot([full()]);
    final dayStamp = DateTime.utc(2026, 4, 2, 10);
    await daysBox.put(
      _k(ago(3)),
      Day(
        date: ago(3),
        habits: [full()..completed = true],
        timestamp: dayStamp,
        isAutoCreated: true,
      ),
    );
    await startProvider();
    final day = daysBox.get(_k(ago(3)))!;
    expect(day.habits.single.hasHabitOnlyFields, isFalse);
    expect(day.habits.single.completed, isTrue);
    expect(day.timestamp, dayStamp);
    expect(day.isAutoCreated, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('daySnapshotsSlimmed_v1'), isTrue);
  });

  test('a past day shows the live habit details', () async {
    await boot([full()], prefs: {'daySnapshotsSlimmed_v1': true});
    await daysBox.put(
      _k(ago(2)),
      Day(
        date: ago(2),
        habits: [full().forDay()..completed = true],
        timestamp: stamp,
      ),
    );
    final p = await startProvider();
    final shown = p.getHabitsFromDay(ago(2)).single;
    expect(shown.description, 'ten pages');
    expect(shown.resolvedName('hr'), 'čitanje');
    expect(shown.streak, 7);
    expect(shown.completed, isTrue);
    expect(p.habitForDay(1, day: ago(2))!.resolvedName('hr'), 'čitanje');

    // writing the day again stores it slim
    await p.updateHabitInDB(shown, day: ago(2));
    expect(daysBox.get(_k(ago(2)))!.habits.single.hasHabitOnlyFields, isFalse);
  });
}
