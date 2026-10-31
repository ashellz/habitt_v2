import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _daysAgo(int days) {
  final today = _normalize(DateTime.now());
  return DateTime(today.year, today.month, today.day - days);
}

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('stats_range_test');
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
    // Short-circuit init() side effects: notification sync already ran today,
    // day snapshots already sanitized.
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

  // one habit on the day [daysAgo] days back
  Future<void> seedDay(int daysAgo, {required bool completed}) async {
    final date = _daysAgo(daysAgo);
    final habit = buildTestHabit(id: 1, trackingType: null)
      ..completed = completed;
    await daysBox.put(
      _dayKey(date),
      Day(date: date, habits: [habit], timestamp: DateTime.now()),
    );
  }

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

  test('the completion rate only counts days inside the range', () async {
    // a completed day inside the week, a missed one inside the month and a
    // completed one further back
    await seedDay(2, completed: true);
    await seedDay(20, completed: false);
    await seedDay(60, completed: true);

    final stats = StatsProvider();
    expect(stats.getCompletionRate(StatsRange.week), 100);
    expect(stats.getCompletionRate(StatsRange.month), 50);
    expect(stats.getCompletionRate(StatsRange.all), 66);
  });

  test('daily rates cover the last N days, oldest first', () async {
    await seedDay(1, completed: true);
    await seedDay(29, completed: true);
    await seedDay(30, completed: true);
    final hp = await createInitializedProvider();

    final rates = StatsProvider().getCompletionRateByDay(hp, 30);

    expect(rates, hasLength(30));
    expect(rates.first, 100); // 29 days ago
    expect(rates[28], 100); // yesterday
    expect(rates.where((rate) => rate > 0), hasLength(2));
  });

  test('weekly rates group 7-day windows counting back from today', () async {
    // window 0 (last 7 days): 1 of 2, window 1: nothing, window 2: 1 of 1
    await seedDay(1, completed: true);
    await seedDay(6, completed: false);
    await seedDay(15, completed: true);
    final hp = await createInitializedProvider();

    final weekly = StatsProvider().getWeeklyCompletionRates(hp);

    expect(weekly.dates, [_daysAgo(14), _daysAgo(0)]);
    expect(weekly.values, [1.0, 0.5]);
  });

  test('the first tracked day is the oldest stored one', () async {
    expect(StatsProvider().firstTrackedDay, isNull);

    await seedDay(3, completed: true);
    await seedDay(40, completed: false);

    expect(StatsProvider().firstTrackedDay, _daysAgo(40));
  });
}
