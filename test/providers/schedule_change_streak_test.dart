import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

DateTime _daysAgo(int n) {
  final today = _normalize(DateTime.now());
  return DateTime(today.year, today.month, today.day - n);
}

List<String> _everyNDaysFrom(DateTime anchor, int interval) => [
  for (var i = 0; i < 180; i += interval)
    _dayKey(DateTime(anchor.year, anchor.month, anchor.day + i)),
];

// Streaks are recomputed from day snapshots, each past day must be judged by
// the schedule the habit had on that day, not by today's schedule.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    await initializeDateFormatting('en');
    tempDir = await Directory.systemTemp.createTemp('schedule_change_streak');
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

  Habit checkbox({ScheduleType scheduleType = ScheduleType.daily}) =>
      buildTestHabit(
        id: 1,
        trackingType: null,
        scheduleType: scheduleType,
        createdAt: _daysAgo(30),
      );

  // Boots the provider with [live] as the current habit, then replaces the
  // day history with [snapshots] (days ago → that day's saved copy).
  Future<HabitProvider> boot(Habit live, Map<int, Habit> snapshots) async {
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _dayKey(DateTime.now()),
      'daySnapshotsSanitized_v1': true,
      'dateJoined': _daysAgo(60).toIso8601String(),
      'play_completion_sound': false,
    });
    await habitBox.clear();
    await daysBox.clear();
    await habitBox.put(live.id, live);

    final provider = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!provider.isInitialized) {
      if (DateTime.now().isAfter(deadline)) fail('HabitProvider.init timed out');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    await daysBox.clear();
    for (final entry in snapshots.entries) {
      final date = _daysAgo(entry.key);
      await daysBox.put(
        _dayKey(date),
        Day(date: date, habits: [entry.value], timestamp: DateTime.now()),
      );
    }
    return provider;
  }

  test('daily → every 3 days keeps the misses from the daily period', () async {
    // Daily for 10 days: done 10..6 days ago, missed 5..3 (breaks the run),
    // done 2..1 days ago. Switched to every 3 days today.
    final snapshots = <int, Habit>{
      for (var n = 10; n >= 1; n--)
        n: checkbox()..completed = !(n >= 3 && n <= 5),
    };
    final live =
        checkbox(scheduleType: ScheduleType.custom)
          ..customIntervalDays = 3
          ..customAppearance = _everyNDaysFrom(_daysAgo(0), 3)
          ..lastCustomUpdate = DateTime.now().toUtc();

    final provider = await boot(live, snapshots);
    await provider.recalculateLongestStreaks(1);
    await provider.assignStreaks(1);

    final habit = habitBox.get(1)!;
    expect(habit.streak, 2);
    expect(habit.longestStreak, 5);
  });

  test('every 4 days → daily does not turn old off-days into misses', () async {
    // Every 4 days, done on each scheduled day (12, 8 and 4 days ago). The
    // off-days are in the snapshots unfinished. Switched to daily today.
    final anchor = _daysAgo(12);
    final schedule = _everyNDaysFrom(anchor, 4);
    final snapshots = <int, Habit>{
      for (var n = 12; n >= 1; n--)
        n:
            checkbox(scheduleType: ScheduleType.custom)
              ..customIntervalDays = 4
              ..customAppearance = List<String>.from(schedule)
              ..lastCustomUpdate = anchor.toUtc()
              ..completed = n % 4 == 0,
    };

    final provider = await boot(checkbox(), snapshots);
    await provider.recalculateLongestStreaks(1);
    await provider.assignStreaks(1);

    final habit = habitBox.get(1)!;
    expect(habit.streak, 3);
    expect(habit.longestStreak, 3);
  });
}
