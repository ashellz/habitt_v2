import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    await initializeDateFormatting('en');
    tempDir = await Directory.systemTemp.createTemp('past_day_streak_test');
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

  late HabitProvider habitProvider;
  late HabitStatsProvider statsProvider;
  late BuildContext context;

  Future<void> boot(
    WidgetTester tester,
    List<Habit> habits, {
    bool watchStats = false,
  }) async {
    final today = _normalize(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _dayKey(today),
      'daySnapshotsSanitized_v1': true,
      'dateJoined': today.subtract(const Duration(days: 60)).toIso8601String(),
      'play_completion_sound': false,
      'show_streak_celebration': false,
    });
    final prefs = await SharedPreferences.getInstance();
    await habitBox.clear();
    await daysBox.clear();
    for (final habit in habits) {
      await habitBox.put(habit.id, habit);
    }

    habitProvider = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!habitProvider.isInitialized) {
      if (DateTime.now().isAfter(deadline)) fail('HabitProvider.init timed out');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    statsProvider =
        HabitStatsProvider()
          ..attachHabitProvider(habitProvider);
    habitProvider.attachHabitStatsProvider(statsProvider);
    // the open details page recomputes its stats on every notification
    if (watchStats) {
      void rebuild() {
        for (final h in habits) {
          statsProvider.statsForHabit(h);
        }
      }

      statsProvider.addListener(rebuild);
      habitProvider.addListener(rebuild);
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HabitProvider>.value(value: habitProvider),
          ChangeNotifierProvider<HabitStatsProvider>.value(value: statsProvider),
          ChangeNotifierProvider(create: (_) => CategoryProvider(habitProvider)),
          ChangeNotifierProvider(create: (_) => StateProvider(prefs)),
          ChangeNotifierProvider(create: (_) => PreferencesProvider(prefs)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  /// What the habit details page shows as the current streak.
  int shownStreak(Habit habit) {
    final stats = statsProvider.statsForHabit(habit);
    final live = habitProvider.habits.firstWhere((h) => h.id == habit.id);
    return stats.currentStreak +
        (live.completed && stats.currentStreak > 0 ? 1 : 0);
  }

  Habit checkbox() => buildTestHabit(
    id: 1,
    trackingType: null,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  );

  Habit amount({bool optional = false}) => buildTestHabit(
    id: 2,
    amount: 10,
    optional: optional,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  );

  Future<void> completeYesterdayThenToday(
    WidgetTester tester,
    Habit habit,
  ) async {
    final today = _normalize(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    await tester.runAsync(() async {
      habitProvider.setSelectedDate(yesterday);
      if (habit.hasTrackingType) {
        habitProvider.updateHabitAmountCompleted(habit.id, habit.amount, context);
      } else {
        habitProvider.completeHabit(
          habit.id,
          context,
          context.read<StateProvider>(),
          playSound: false,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));

      habitProvider.setSelectedDate(today);
      if (habit.hasTrackingType) {
        habitProvider.updateHabitAmountCompleted(habit.id, habit.amount, context);
      } else {
        habitProvider.completeHabit(
          habit.id,
          context,
          context.read<StateProvider>(),
          playSound: false,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
  }

  testWidgets('checkbox habit: past day then today shows streak 2', (
    tester,
  ) async {
    final habit = checkbox();
    await tester.runAsync(() => boot(tester, [habit]));
    await completeYesterdayThenToday(tester, habit);

    expect(shownStreak(habit), 2);
  });

  testWidgets('amount habit: past day then today shows streak 2', (
    tester,
  ) async {
    final habit = amount();
    await tester.runAsync(() => boot(tester, [habit]));
    await completeYesterdayThenToday(tester, habit);

    expect(shownStreak(habit), 2);
  });

  for (final isAmount in [false, true]) {
    testWidgets(
      '${isAmount ? 'amount' : 'checkbox'} habit with the details page open '
      'shows streak 2',
      (tester) async {
        final habit = isAmount ? amount() : checkbox();
        await tester.runAsync(() => boot(tester, [habit], watchStats: true));
        await completeYesterdayThenToday(tester, habit);

        expect(shownStreak(habit), 2);
      },
    );
  }

  testWidgets('optional amount habit: past day then today shows streak 2', (
    tester,
  ) async {
    final habit = amount(optional: true);
    await tester.runAsync(() => boot(tester, [habit]));
    await completeYesterdayThenToday(tester, habit);

    expect(shownStreak(habit), 2);
  });
}
