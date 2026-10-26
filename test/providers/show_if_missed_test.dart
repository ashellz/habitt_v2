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

Habit _weeklyHabit({
  required int weekday,
  required DateTime createdAt,
  bool showIfMissed = true,
  bool completed = false,
}) {
  return Habit(
    id: 1,
    name: 'omega 3',
    iconPath: '',
    categoryId: 0,
    scheduleType: ScheduleType.weekly,
    selectedDaysAWeek: [weekday],
    showIfMissed: showIfMissed,
    completed: completed,
    createdAt: createdAt,
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
  final longAgo = today.subtract(const Duration(days: 100));
  // A weekly habit scheduled on the weekday that was 2 days ago.
  final scheduledWeekday = today.subtract(const Duration(days: 2)).weekday;

  Future<void> recordDay(DateTime date, Habit habit) async {
    await daysBox.put(
      _dayKey(date),
      Day(date: date, habits: [habit.copy()], timestamp: DateTime.now()),
    );
  }

  group('show if missed', () {
    test('keeps showing after a missed scheduled day', () async {
      final provider = await createInitializedProvider();
      final habit = _weeklyHabit(weekday: scheduledWeekday, createdAt: longAgo);
      await recordDay(
        today.subtract(const Duration(days: 2)),
        _weeklyHabit(weekday: scheduledWeekday, createdAt: longAgo),
      );

      expect(provider.appearsOnDay(habit, today), isTrue);
    });

    test('toggle off: does not show off-schedule days', () async {
      final provider = await createInitializedProvider();
      final habit = _weeklyHabit(
        weekday: scheduledWeekday,
        createdAt: longAgo,
        showIfMissed: false,
      );

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('stops once completed on the scheduled day', () async {
      final provider = await createInitializedProvider();
      final habit = _weeklyHabit(weekday: scheduledWeekday, createdAt: longAgo);
      await recordDay(
        today.subtract(const Duration(days: 2)),
        _weeklyHabit(
          weekday: scheduledWeekday,
          createdAt: longAgo,
          completed: true,
        ),
      );

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('stops once completed on a carry-over day', () async {
      final provider = await createInitializedProvider();
      final habit = _weeklyHabit(weekday: scheduledWeekday, createdAt: longAgo);
      await recordDay(
        today.subtract(const Duration(days: 1)),
        _weeklyHabit(
          weekday: scheduledWeekday,
          createdAt: longAgo,
          completed: true,
        ),
      );

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('never carries over to past days (streaks unaffected)', () async {
      final provider = await createInitializedProvider();
      final habit = _weeklyHabit(weekday: scheduledWeekday, createdAt: longAgo);

      expect(
        provider.appearsOnDay(habit, today.subtract(const Duration(days: 1))),
        isFalse,
      );
    });

    test('does not carry over from before the habit was created', () async {
      final provider = await createInitializedProvider();
      final habit = _weeklyHabit(
        weekday: scheduledWeekday,
        createdAt: today.subtract(const Duration(days: 1)),
      );

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('custom interval carries over until the next occurrence', () async {
      final provider = await createInitializedProvider();
      final createdAt = today.subtract(const Duration(days: 10));
      final habit = Habit(
        id: 1,
        name: 'custom',
        iconPath: '',
        categoryId: 0,
        scheduleType: ScheduleType.custom,
        customIntervalDays: 5,
        showIfMissed: true,
        createdAt: createdAt,
        lastCustomUpdate: createdAt,
        customAppearance: [
          for (var i = 0; i < 365; i += 5)
            _dayKey(createdAt.add(Duration(days: i))),
        ],
      );
      // Scheduled days: -10, -5, 0 (today). Today is scheduled itself.
      expect(provider.appearsOnDay(habit, today), isTrue);
      // Day after a missed -5 is not today, so no carry-over is evaluated.
      expect(
        provider.appearsOnDay(habit, today.subtract(const Duration(days: 4))),
        isFalse,
      );
    });
  });
}
