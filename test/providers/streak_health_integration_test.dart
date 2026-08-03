import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/models/streak_health.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

enum _Outcome { perfect, miss, partial }

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'streak_health_integration',
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
      'dateJoined': today.subtract(const Duration(days: 60)).toIso8601String(),
    });
    await habitBox.clear();
    await daysBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Habit snapshot(_Outcome outcome) {
    return buildTestHabit(
      amountCompleted: switch (outcome) {
        _Outcome.perfect => 10,
        _Outcome.partial => 4,
        _Outcome.miss => 0,
      },
    )..completed = outcome == _Outcome.perfect;
  }

  /// Seeds [history] (oldest → newest) on the days before today.
  Future<void> seedHistory(List<_Outcome> history) async {
    await habitBox.put(1, buildTestHabit(id: 1));

    final today = _normalize(DateTime.now());
    for (int i = 0; i < history.length; i++) {
      final date = today.subtract(Duration(days: history.length - i));
      await daysBox.put(
        _dayKey(date),
        Day(
          date: date,
          habits: [snapshot(history[i])],
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<(HabitProvider, StatsProvider)> boot() async {
    final habitProvider = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!habitProvider.isInitialized) {
      if (DateTime.now().isAfter(deadline)) {
        fail('HabitProvider.init did not complete');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    final statsProvider = StatsProvider();
    statsProvider.attachHabitProvider(habitProvider);
    await habitProvider.assignStreaks();
    statsProvider.refreshStats(force: true);
    return (habitProvider, statsProvider);
  }

  /// Marks today's only habit complete and pushes the change through the caches
  /// the way a real completion would.
  void completeToday(HabitProvider hp, StatsProvider sp) {
    for (final habit in hp.todaysHabits) {
      habit.completed = true;
      habit.amountCompleted = habit.amount;
    }
    sp.refreshStats(force: true);
  }

  group('perfect-days health end to end', () {
    test('an unbroken run is healthy', () async {
      await seedHistory([_Outcome.perfect, _Outcome.perfect, _Outcome.perfect]);
      final (_, sp) = await boot();

      expect(sp.perfectDaysStreak, 3);
      expect(sp.perfectDaysTailMisses, 0);
      expect(sp.perfectDaysHealth, StreakHealth.healthy);
    });

    test('one miss since the last perfect day is fading', () async {
      await seedHistory([_Outcome.perfect, _Outcome.perfect, _Outcome.miss]);
      final (_, sp) = await boot();

      expect(sp.perfectDaysStreak, 2);
      expect(sp.perfectDaysTailMisses, 1);
      expect(sp.perfectDaysHealth, StreakHealth.fading);
    });

    test('two misses is critical', () async {
      await seedHistory([
        _Outcome.perfect,
        _Outcome.perfect,
        _Outcome.miss,
        _Outcome.miss,
      ]);
      final (_, sp) = await boot();

      expect(sp.perfectDaysStreak, 2);
      expect(sp.perfectDaysTailMisses, 2);
      expect(sp.perfectDaysHealth, StreakHealth.critical);
    });

    test('a neutral day between misses still reaches critical', () async {
      // The user did not miss "yesterday and the day before" — a partial day
      // sits between the two misses — but tolerance is equally spent.
      await seedHistory([
        _Outcome.perfect,
        _Outcome.miss,
        _Outcome.partial,
        _Outcome.miss,
      ]);
      final (_, sp) = await boot();

      expect(sp.perfectDaysTailMisses, 2);
      expect(sp.perfectDaysHealth, StreakHealth.critical);
    });

    test('completing today clears critical within the same session', () async {
      await seedHistory([
        _Outcome.perfect,
        _Outcome.perfect,
        _Outcome.miss,
        _Outcome.miss,
      ]);
      final (hp, sp) = await boot();
      expect(sp.perfectDaysHealth, StreakHealth.critical);

      completeToday(hp, sp);

      expect(sp.todayCompletionStatus, DayCompletionStatus.perfect);
      expect(sp.perfectDaysHealth, StreakHealth.healthy);
      // Spent tolerance is unchanged — today is excluded from the streak walk.
      // Only the live status flipped the state.
      expect(sp.perfectDaysTailMisses, 2);
    });

    test('a broken streak is dormant, not critical', () async {
      await seedHistory([
        _Outcome.perfect,
        _Outcome.miss,
        _Outcome.miss,
        _Outcome.miss,
      ]);
      final (_, sp) = await boot();

      expect(sp.perfectDaysStreak, 0);
      expect(sp.perfectDaysTailMisses, 3);
      expect(sp.perfectDaysHealth, StreakHealth.dormant);
    });
  });

  group('widget and badge agree for a single-habit user', () {
    test('both read critical, then both clear together', () async {
      await seedHistory([
        _Outcome.perfect,
        _Outcome.perfect,
        _Outcome.miss,
        _Outcome.miss,
      ]);
      final (hp, sp) = await boot();

      final habit = hp.habits.firstWhere((h) => h.id == 1);
      expect(sp.perfectDaysHealth, StreakHealth.critical);
      expect(hp.streakHealthFor(habit), StreakHealth.critical);

      completeToday(hp, sp);

      expect(sp.perfectDaysHealth, StreakHealth.healthy);
      expect(hp.streakHealthFor(habit), StreakHealth.healthy);
    });

    test('both read fading at one spent miss', () async {
      await seedHistory([_Outcome.perfect, _Outcome.perfect, _Outcome.miss]);
      final (hp, sp) = await boot();

      final habit = hp.habits.firstWhere((h) => h.id == 1);
      expect(sp.perfectDaysHealth, StreakHealth.fading);
      expect(hp.streakHealthFor(habit), StreakHealth.fading);
    });
  });
}
