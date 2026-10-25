import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../fixtures/habit_factory.dart';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Day> daysBox;

  setUpAll(() async {
    await initializeDateFormatting('en');
    tempDir = await Directory.systemTemp.createTemp('habit_stats_today_test');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    Hive.registerAdapter(ScheduleTypeAdapter());
    Hive.registerAdapter(PremadeHabitTypeAdapter());
    Hive.registerAdapter(HabitTrackingTypeAdapter());
    Hive.registerAdapter(HabitNotificationTimeAdapter());
    Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
    await Hive.openBox<Habit>('habits');
    daysBox = await Hive.openBox<Day>('days');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await daysBox.clear();
  });

  // one stored day per entry, `completed` flags oldest first, last is today
  Future<Habit> seedDays(List<bool> completedByDay) async {
    final today = _normalize(DateTime.now());
    final habit = buildTestHabit(id: 1, trackingType: null);
    for (var i = 0; i < completedByDay.length; i++) {
      final date = today.subtract(Duration(days: completedByDay.length - 1 - i));
      final snapshot = buildTestHabit(id: 1, trackingType: null)
        ..completed = completedByDay[i];
      await daysBox.add(
        Day(date: date, habits: [snapshot], timestamp: DateTime.now()),
      );
    }
    return habit;
  }

  test('an incomplete today is not counted as a miss', () async {
    final habit = await seedDays([true, true, false]);

    final stats = HabitStatsProvider().statsForHabit(
      habit,
      locale: const Locale('en'),
    );

    expect(stats.completedCount, 2);
    expect(stats.missedCount, 0);
    for (final range in StatsRange.values) {
      expect(stats.rangeStats[range]!.completionRatio, 1.0, reason: '$range');
    }
  });

  test('a completed today counts straight away', () async {
    final habit = await seedDays([true, false, true]);

    final stats = HabitStatsProvider().statsForHabit(
      habit,
      locale: const Locale('en'),
    );

    expect(stats.completedCount, 2);
    expect(stats.missedCount, 1);
    for (final range in StatsRange.values) {
      expect(
        stats.rangeStats[range]!.completionRatio,
        closeTo(2 / 3, 0.0001),
        reason: '$range',
      );
    }
  });

  test('a past incomplete day is still a miss', () async {
    final habit = await seedDays([false, true, false]);

    final stats = HabitStatsProvider().statsForHabit(
      habit,
      locale: const Locale('en'),
    );

    expect(stats.completedCount, 1);
    expect(stats.missedCount, 1);
  });
}
