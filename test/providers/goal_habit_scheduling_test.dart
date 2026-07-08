import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime _normalize(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

/// A checkbox-style (no amount/duration tracking) weekly target-only habit —
/// `selectedDaysAWeek` empty means "N times a week", no specific days.
Habit _weeklyTargetHabit({
  required int id,
  required int weeklyTarget,
  bool completed = false,
  int timesCompletedThisWeek = 0,
  DateTime? weekTimestamp,
}) {
  return Habit(
    id: id,
    name: 'w$id',
    iconPath: '',
    categoryId: 0,
    scheduleType: ScheduleType.weekly,
    weeklyTarget: weeklyTarget,
    completed: completed,
    timesCompletedThisWeek: timesCompletedThisWeek,
    timestamps:
        weekTimestamp == null
            ? null
            : {'timesCompletedThisWeek': weekTimestamp},
  );
}

Habit _monthlyTargetHabit({
  required int id,
  required int monthlyTarget,
  bool completed = false,
  int timesCompletedThisMonth = 0,
  DateTime? monthTimestamp,
}) {
  return Habit(
    id: id,
    name: 'm$id',
    iconPath: '',
    categoryId: 0,
    scheduleType: ScheduleType.monthly,
    monthlyTarget: monthlyTarget,
    completed: completed,
    timesCompletedThisMonth: timesCompletedThisMonth,
    timestamps:
        monthTimestamp == null
            ? null
            : {'timesCompletedThisMonth': monthTimestamp},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'goal_habit_scheduling_test',
    );
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

  // Monday of a week N weeks before the current week — always in the past,
  // regardless of when the suite runs.
  DateTime mondayWeeksAgo(int weeks) {
    final now = DateTime.now();
    final thisMonday = _normalize(
      now,
    ).subtract(Duration(days: now.weekday - 1));
    return thisMonday.subtract(Duration(days: 7 * weeks));
  }

  group('appearsOnDay — weekly target-only critical window', () {
    test('today always appears while target unmet, regardless of weekday', () async {
      final provider = await createInitializedProvider();
      final now = DateTime.now();
      final habit = _weeklyTargetHabit(
        id: 1,
        weeklyTarget: 3,
        timesCompletedThisWeek: 0,
        weekTimestamp: now.toUtc(),
      );
      expect(provider.appearsOnDay(habit, now), isTrue);
    });

    test('past non-critical day with zero progress is not due', () async {
      final provider = await createInitializedProvider();
      final monday = mondayWeeksAgo(5);
      final habit = _weeklyTargetHabit(
        id: 1,
        weeklyTarget: 3,
        timesCompletedThisWeek: 0,
        weekTimestamp: monday.add(const Duration(hours: 12)).toUtc(),
      );
      // Monday: 7 days left, 3 owed -> not critical.
      expect(provider.appearsOnDay(habit, monday), isFalse);
      // Thursday: 4 days left, 3 owed -> not critical.
      expect(
        provider.appearsOnDay(habit, monday.add(const Duration(days: 3))),
        isFalse,
      );
    });

    test('past critical day is due regardless of completion', () async {
      final provider = await createInitializedProvider();
      final monday = mondayWeeksAgo(5);
      final habit = _weeklyTargetHabit(
        id: 1,
        weeklyTarget: 3,
        timesCompletedThisWeek: 0,
        weekTimestamp: monday.add(const Duration(hours: 12)).toUtc(),
      );
      // Friday: 3 days left, 3 owed -> critical.
      final friday = monday.add(const Duration(days: 4));
      expect(provider.appearsOnDay(habit, friday), isTrue);
      // Sunday: 1 day left, 3 owed -> critical.
      final sunday = monday.add(const Duration(days: 6));
      expect(provider.appearsOnDay(habit, sunday), isTrue);
    });

    test('completing early shrinks the later critical window', () async {
      final provider = await createInitializedProvider();
      final monday = mondayWeeksAgo(5);
      final habit = _weeklyTargetHabit(
        id: 1,
        weeklyTarget: 3,
        timesCompletedThisWeek: 1, // one completion already banked this week
        weekTimestamp: monday.add(const Duration(hours: 12)).toUtc(),
      );
      // Friday is now non-critical: 2 owed, 3 days left.
      final friday = monday.add(const Duration(days: 4));
      expect(provider.appearsOnDay(habit, friday), isFalse);
      // Saturday becomes the new critical start: 2 owed, 2 days left.
      final saturday = monday.add(const Duration(days: 5));
      expect(provider.appearsOnDay(habit, saturday), isTrue);
    });

    test('target already met is never due again in the period', () async {
      final provider = await createInitializedProvider();
      final monday = mondayWeeksAgo(5);
      final habit = _weeklyTargetHabit(
        id: 1,
        weeklyTarget: 3,
        timesCompletedThisWeek: 3,
        weekTimestamp: monday.add(const Duration(hours: 12)).toUtc(),
      );
      final sunday = monday.add(const Duration(days: 6));
      expect(provider.appearsOnDay(habit, sunday), isFalse);
    });

    test('explicit selected days are unaffected by critical-day logic', () async {
      final provider = await createInitializedProvider();
      final monday = mondayWeeksAgo(5);
      final habit = Habit(
        id: 1,
        name: 'explicit',
        iconPath: '',
        categoryId: 0,
        scheduleType: ScheduleType.weekly,
        selectedDaysAWeek: const [1, 3, 5], // Mon/Wed/Fri
        weeklyTarget: 3,
      );
      expect(provider.appearsOnDay(habit, monday), isTrue); // Monday selected
      expect(
        provider.appearsOnDay(habit, monday.add(const Duration(days: 1))),
        isFalse, // Tuesday not selected
      );
    });
  });

  group('appearsOnDay — monthly target-only critical window', () {
    // Fixed historical month so the day-of-month math is deterministic,
    // regardless of when the suite runs.
    test('past non-critical day with zero progress is not due', () async {
      final provider = await createInitializedProvider();
      final habit = _monthlyTargetHabit(
        id: 1,
        monthlyTarget: 3,
        timesCompletedThisMonth: 0,
        monthTimestamp: DateTime(2019, 1, 1, 12).toUtc(),
      );
      // Jan 5 1970-style fixed month: 27 days left in January -> not critical.
      expect(provider.appearsOnDay(habit, DateTime(2019, 1, 5)), isFalse);
    });

    test('past critical day is due regardless of completion', () async {
      final provider = await createInitializedProvider();
      final habit = _monthlyTargetHabit(
        id: 1,
        monthlyTarget: 3,
        timesCompletedThisMonth: 0,
        monthTimestamp: DateTime(2019, 1, 1, 12).toUtc(),
      );
      // Jan 29: daysLeft = 31-29+1 = 3, owed = 3 -> critical.
      expect(provider.appearsOnDay(habit, DateTime(2019, 1, 29)), isTrue);
      // Jan 28: daysLeft = 4, owed = 3 -> not critical.
      expect(provider.appearsOnDay(habit, DateTime(2019, 1, 28)), isFalse);
    });
  });

  group('habitsCountingForDay + classifyDayStatus — perfectDaysStreak effect', () {
    test('day is not downgraded by a non-critical unmet target habit', () async {
      final provider = await createInitializedProvider();
      final monday = mondayWeeksAgo(5);

      final dailyHabit = Habit(
        id: 1,
        name: 'daily',
        iconPath: '',
        categoryId: 0,
        scheduleType: ScheduleType.daily,
        completed: true,
      );
      final targetHabit = _weeklyTargetHabit(
        id: 2,
        weeklyTarget: 3,
        completed: false,
        timesCompletedThisWeek: 0,
        weekTimestamp: monday.add(const Duration(hours: 12)).toUtc(),
      );

      final counting = provider.habitsCountingForDay(monday, [
        dailyHabit,
        targetHabit,
      ]);
      expect(counting.map((h) => h.id), [1]); // target habit excluded
      expect(classifyDayStatus(counting), DayCompletionStatus.perfect);
    });

    test('day is downgraded when a critical target habit is missed', () async {
      final provider = await createInitializedProvider();
      final monday = mondayWeeksAgo(5);
      final friday = monday.add(const Duration(days: 4));

      final dailyHabit = Habit(
        id: 1,
        name: 'daily',
        iconPath: '',
        categoryId: 0,
        scheduleType: ScheduleType.daily,
        completed: true,
      );
      final targetHabit = _weeklyTargetHabit(
        id: 2,
        weeklyTarget: 3,
        completed: false,
        timesCompletedThisWeek: 0,
        weekTimestamp: monday.add(const Duration(hours: 12)).toUtc(),
      );

      final counting = provider.habitsCountingForDay(friday, [
        dailyHabit,
        targetHabit,
      ]);
      expect(counting.map((h) => h.id).toSet(), {1, 2}); // critical, included
      expect(classifyDayStatus(counting), DayCompletionStatus.miss);
    });
  });

  group('assignStreaks — weekly target-only habits', () {
    Future<void> seedWeek(
      DateTime monday, {
      required int id,
      required int weeklyTarget,
      required List<bool> completedByWeekday, // index 0 = Monday
    }) async {
      int cumulative = 0;
      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        final completedToday = completedByWeekday[i];
        if (completedToday) cumulative++;
        await daysBox.put(
          _dayKey(day),
          Day(
            date: _normalize(day),
            habits: [
              _weeklyTargetHabit(
                id: id,
                weeklyTarget: weeklyTarget,
                completed: completedToday,
                timesCompletedThisWeek: cumulative,
                weekTimestamp: day.add(const Duration(hours: 12)).toUtc(),
              ),
            ],
            timestamp: DateTime.now().toUtc(),
          ),
        );
      }
    }

    // dateJoined is pinned to today (instead of the shared setUp's far-past
    // value) so init()'s missing-day backfill has nothing to do — otherwise
    // it would synthesize weeks of critical, unmet-target days between the
    // seeded test week and today, which would themselves break the streak
    // before the loop ever reaches the week under test.
    Future<HabitProvider> createProviderWithNoBackfill() async {
      final today = _normalize(DateTime.now());
      SharedPreferences.setMockInitialValues({
        'lastNotificationSyncDate': _dayKey(today),
        'daySnapshotsSanitized_v1': true,
        'dateJoined': today.toIso8601String(),
      });
      return createInitializedProvider();
    }

    test('non-critical zero-progress days do not break the streak', () async {
      final provider = await createProviderWithNoBackfill();
      final monday = mondayWeeksAgo(5);
      // Nothing Mon-Thu (non-critical, excluded); target hit exactly across
      // the critical Fri/Sat/Sun window.
      await seedWeek(
        monday,
        id: 1,
        weeklyTarget: 3,
        completedByWeekday: [false, false, false, false, true, true, true],
      );
      await habitBox.add(_weeklyTargetHabit(id: 1, weeklyTarget: 3));

      await provider.assignStreaks();

      final habit = provider.habitBox.values.firstWhere((h) => h.id == 1);
      expect(habit.streak, 3);
    });

    test('a fully skipped week still breaks the streak on its critical days', () async {
      final provider = await createProviderWithNoBackfill();
      final monday = mondayWeeksAgo(5);
      await seedWeek(
        monday,
        id: 1,
        weeklyTarget: 3,
        completedByWeekday: List.filled(7, false),
      );
      await habitBox.add(_weeklyTargetHabit(id: 1, weeklyTarget: 3));

      await provider.assignStreaks();

      final habit = provider.habitBox.values.firstWhere((h) => h.id == 1);
      expect(habit.streak, 0);
    });
  });
}
