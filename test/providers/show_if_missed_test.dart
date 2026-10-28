import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime _normalize(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

String _key(DateTime d) => _dayKey(d);

/// Custom "every 3 days" habit whose grid is anchored [anchorDaysAgo] days
/// ago, so with anchorDaysAgo = 8 the scheduled days are -8, -5, -2, +1, ...
Habit _customHabit({
  required int anchorDaysAgo,
  bool showIfMissed = true,
  bool completed = false,
}) {
  final today = _normalize(DateTime.now());
  final anchor = today.subtract(Duration(days: anchorDaysAgo));
  return Habit(
    id: 1,
    name: 'omega 3',
    iconPath: '',
    categoryId: 0,
    scheduleType: ScheduleType.custom,
    customIntervalDays: 3,
    showIfMissed: showIfMissed,
    completed: completed,
    createdAt: today.subtract(const Duration(days: 100)),
    lastCustomUpdate: anchor,
    customAppearance: [
      for (var i = 0; i < 365; i += 3) _key(anchor.add(Duration(days: i))),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('show_if_missed_test');
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

  setUp(() async {
    final today = _normalize(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _dayKey(today),
      'daySnapshotsSanitized_v1': true,
      'dateJoined': today.subtract(const Duration(days: 400)).toIso8601String(),
    });
    await habitBox.clear();
    await daysBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<HabitProvider> createInitializedProvider() async {
    final provider = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!provider.isInitialized) {
      if (DateTime.now().isAfter(deadline)) {
        fail('HabitProvider.init did not complete');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return provider;
  }

  final today = _normalize(DateTime.now());

  Future<void> recordDay(DateTime date, Habit habit) async {
    await daysBox.put(
      _dayKey(date),
      Day(date: date, habits: [habit.copy()], timestamp: DateTime.now()),
    );
  }

  group('show if missed (custom interval)', () {
    test('keeps showing after a missed scheduled day', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8);
      await recordDay(
        today.subtract(const Duration(days: 2)),
        _customHabit(anchorDaysAgo: 8),
      );

      expect(provider.appearsOnDay(habit, today), isTrue);
    });

    test('toggle off: does not show off-schedule days', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8, showIfMissed: false);

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('stops once completed on the scheduled day', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8);
      await recordDay(
        today.subtract(const Duration(days: 2)),
        _customHabit(anchorDaysAgo: 8, completed: true),
      );

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('never carries over to past days (streaks unaffected)', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8);

      expect(
        provider.appearsOnDay(habit, today.subtract(const Duration(days: 1))),
        isFalse,
      );
    });

    test('does not apply to weekly habits', () async {
      final provider = await createInitializedProvider();
      final habit = Habit(
        id: 1,
        name: 'weekly',
        iconPath: '',
        categoryId: 0,
        scheduleType: ScheduleType.weekly,
        selectedDaysAWeek: [today.subtract(const Duration(days: 2)).weekday],
        showIfMissed: true,
        createdAt: today.subtract(const Duration(days: 100)),
      );

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('late completion restarts the interval from that day', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8);
      await habitBox.add(habit);
      await recordDay(
        today.subtract(const Duration(days: 2)),
        _customHabit(anchorDaysAgo: 8),
      );
      expect(provider.appearsOnDay(habit, today), isTrue);

      habit.completed = true;
      await provider.updateHabitInDB(habit);

      expect(
        habit.customAppearance,
        containsAll([
          _key(today.subtract(const Duration(days: 2))), // history kept
          _key(today),
          _key(today.add(const Duration(days: 3))),
        ]),
      );
      expect(
        habit.customAppearance.contains(_key(today.add(const Duration(days: 1)))),
        isFalse,
      );
    });
  });
}
