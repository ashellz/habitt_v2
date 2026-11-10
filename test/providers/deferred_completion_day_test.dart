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
import 'package:habitt/util/date_key.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

/// A "Done" tapped on a notification is queued with its day and applied later
/// by [HabitProvider.applyDeferredCompletion]. It must land on that day, not on
/// today and not on whatever day the main page happens to show.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    await initializeDateFormatting('en');
    tempDir = await Directory.systemTemp.createTemp('deferred_completion_test');
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

  Habit checkbox() => buildTestHabit(
    id: 1,
    trackingType: null,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
  );

  bool liveCompleted() =>
      habitProvider.habits.firstWhere((h) => h.id == 1).completed;

  /// The habit's completion in the stored day record, null if none.
  bool? storedCompleted(DateTime day) {
    final record = daysBox.get(_dayKey(day));
    if (record == null) return null;
    for (final h in record.habits) {
      if (h.id == 1) return h.completed;
    }
    return null;
  }

  Future<void> drain(DateTime day) async {
    habitProvider.applyDeferredCompletion(
      1,
      day,
      context,
      context.read<StateProvider>(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  testWidgets('a queued completion for yesterday completes yesterday only', (
    tester,
  ) async {
    await tester.runAsync(() => boot(tester, [checkbox()]));
    final today = _normalize(DateTime.now());
    final yesterday = addCalendarDays(today, -1);

    await tester.runAsync(() => drain(yesterday));

    expect(storedCompleted(yesterday), isTrue);
    expect(
      habitProvider.getHabitsFromDay(yesterday).firstWhere((h) => h.id == 1)
          .completed,
      isTrue,
    );
    expect(liveCompleted(), isFalse);
    expect(storedCompleted(today), isNot(true));
  });

  testWidgets(
    'a queued completion for today completes today while a past day is shown',
    (tester) async {
      await tester.runAsync(() => boot(tester, [checkbox()]));
      final today = _normalize(DateTime.now());
      final yesterday = addCalendarDays(today, -1);

      await tester.runAsync(() async {
        habitProvider.setSelectedDate(yesterday);
        await drain(today);
      });

      expect(liveCompleted(), isTrue);
      expect(storedCompleted(yesterday), isNot(true));
      expect(habitProvider.selectedDate, yesterday);
    },
  );

  testWidgets('draining the same past day twice keeps it completed', (
    tester,
  ) async {
    await tester.runAsync(() => boot(tester, [checkbox()]));
    final today = _normalize(DateTime.now());
    final yesterday = addCalendarDays(today, -1);

    await tester.runAsync(() async {
      await drain(yesterday);
      await drain(yesterday);
    });

    expect(storedCompleted(yesterday), isTrue);
    expect(liveCompleted(), isFalse);
  });
}
