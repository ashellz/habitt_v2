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
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/services/watch_action_queue.dart';
import 'package:habitt/util/date_key.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

/// Changes made on the Apple Watch are applied by
/// [HabitProvider.applyWatchAction] on the action's day, through the same code
/// as the app (docs/watch_app.md).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    await initializeDateFormatting('en');
    tempDir = await Directory.systemTemp.createTemp('watch_action_apply_test');
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
  late BuildContext context;

  Future<void> boot(WidgetTester tester, List<Habit> habits) async {
    final today = _normalize(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _dayKey(today),
      'daySnapshotsSanitized_v1': true,
      'dateJoined': addCalendarDays(today, -60).toIso8601String(),
      'play_completion_sound': false,
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
    final statsProvider =
        HabitStatsProvider()..attachHabitProvider(habitProvider);
    habitProvider.attachHabitStatsProvider(statsProvider);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HabitProvider>.value(value: habitProvider),
          ChangeNotifierProvider<HabitStatsProvider>.value(value: statsProvider),
          ChangeNotifierProvider(create: (_) => CategoryProvider(habitProvider)),
          ChangeNotifierProvider(create: (_) => StateProvider(prefs)),
          ChangeNotifierProvider(create: (_) => StatsProvider(prefs: prefs)),
          ChangeNotifierProvider(
            create:
                (_) => SupportProvider(
                  prefs,
                  readSupporter: () => false,
                  checkSupporter: () async => false,
                  platformSupportsAsks: false,
                ),
          ),
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

  final created = DateTime.now().subtract(const Duration(days: 10));

  Habit checkbox() =>
      buildTestHabit(id: 1, trackingType: null, createdAt: created);

  Habit pages() => buildTestHabit(
    id: 1,
    amount: 10,
    amountLabel: 'pages',
    premadeHabitType: null,
    createdAt: created,
  );

  Habit meditate() => buildTestHabit(
    id: 1,
    trackingType: HabitTrackingType.duration,
    duration: 600,
    premadeHabitType: null,
    createdAt: created,
  );

  Habit live() => habitProvider.habits.firstWhere((h) => h.id == 1);

  Future<bool> apply(
    WatchActionType type, {
    DateTime? day,
    int? value,
  }) async {
    final d = day ?? _normalize(DateTime.now());
    final changed = habitProvider.applyWatchAction(
      WatchAction(
        v: 1,
        id: 'a${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        habitId: 1,
        day: d,
        at: DateTime.now(),
        value: value,
      ),
      context,
      context.read<StateProvider>(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return changed;
  }

  testWidgets('complete, then uncomplete today', (tester) async {
    await tester.runAsync(() => boot(tester, [checkbox()]));
    await tester.runAsync(() async {
      expect(await apply(WatchActionType.complete), isTrue);
    });
    expect(live().completed, isTrue);
    await tester.runAsync(() async {
      // a second complete changes nothing
      expect(await apply(WatchActionType.complete), isFalse);
      expect(await apply(WatchActionType.uncomplete), isTrue);
    });
    expect(live().completed, isFalse);
  });

  testWidgets('setAmount below then at the target', (tester) async {
    await tester.runAsync(() => boot(tester, [pages()]));
    await tester.runAsync(() => apply(WatchActionType.setAmount, value: 8));
    expect(live().amountCompleted, 8);
    expect(live().completed, isFalse);
    await tester.runAsync(() => apply(WatchActionType.setAmount, value: 10));
    expect(live().completed, isTrue);
    await tester.runAsync(() => apply(WatchActionType.uncomplete));
    expect(live().amountCompleted, 0);
    expect(live().completed, isFalse);
  });

  testWidgets('setDuration in seconds', (tester) async {
    await tester.runAsync(() => boot(tester, [meditate()]));
    await tester.runAsync(() => apply(WatchActionType.setDuration, value: 360));
    expect(live().durationCompleted, 360);
    expect(live().completed, isFalse);
  });

  testWidgets('an action for yesterday lands on yesterday only', (tester) async {
    await tester.runAsync(() => boot(tester, [checkbox()]));
    final yesterday = addCalendarDays(_normalize(DateTime.now()), -1);
    await tester.runAsync(
      () => apply(WatchActionType.complete, day: yesterday),
    );
    expect(
      habitProvider.getHabitsFromDay(yesterday).firstWhere((h) => h.id == 1)
          .completed,
      isTrue,
    );
    expect(live().completed, isFalse);
  });

  testWidgets('Health-linked, wrong type and deleted habits are dropped', (
    tester,
  ) async {
    final steps = pages()..healthMetric = HealthMetricType.steps;
    await tester.runAsync(() => boot(tester, [steps]));
    await tester.runAsync(() async {
      expect(await apply(WatchActionType.setAmount, value: 5), isFalse);
      expect(await apply(WatchActionType.complete), isFalse);
    });
    expect(live().amountCompleted, 0);

    await tester.runAsync(() => boot(tester, [pages()]));
    await tester.runAsync(() async {
      expect(await apply(WatchActionType.setDuration, value: 60), isFalse);
    });

    final gone = pages()..isDeleted = true;
    await tester.runAsync(() => boot(tester, [gone]));
    await tester.runAsync(() async {
      expect(await apply(WatchActionType.complete), isFalse);
    });
  });
}
