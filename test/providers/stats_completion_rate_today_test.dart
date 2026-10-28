import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:hive_ce/hive.dart';

import '../fixtures/habit_factory.dart';

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('stats_rate_today_test');
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

  // `completed` flags of one habit per day, oldest first, the last is today
  Future<void> seed(List<bool> completedByDay) async {
    final today = _normalize(DateTime.now());
    for (var i = 0; i < completedByDay.length; i++) {
      final date = today.subtract(Duration(days: completedByDay.length - 1 - i));
      final habit = buildTestHabit(id: 1, trackingType: null)
        ..completed = completedByDay[i];
      await daysBox.add(
        Day(date: date, habits: [habit], timestamp: DateTime.now()),
      );
    }
  }

  test('an incomplete today does not lower the completion rate', () async {
    await seed([true, false, false]);

    expect(StatsProvider().getCompletionRateLastWeek(), 50);
  });

  test('a completed today counts straight away', () async {
    await seed([true, false, true]);

    // 2 of 3, it used to stay at 1 of 2 until the day was over
    expect(StatsProvider().getCompletionRateLastWeek(), 66);
  });

  test('the rate follows today without being recreated', () async {
    await seed([true, false, false]);
    final stats = StatsProvider();
    expect(stats.getCompletionRateLastWeek(), 50);

    daysBox.values.last.habits.single.completed = true;

    expect(stats.getCompletionRateLastWeek(), 66);
  });
}
