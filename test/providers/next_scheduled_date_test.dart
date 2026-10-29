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

DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

Habit _habit({
  ScheduleType scheduleType = ScheduleType.daily,
  List<int>? selectedDaysAWeek,
  List<int>? selectedDaysAMonth,
  bool? isPaused,
}) {
  return Habit(
    id: 1,
    name: 'run',
    iconPath: '',
    categoryId: 0,
    scheduleType: scheduleType,
    selectedDaysAWeek: selectedDaysAWeek,
    selectedDaysAMonth: selectedDaysAMonth,
    isPaused: isPaused,
    createdAt: DateTime.now().subtract(const Duration(days: 100)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HabitProvider provider;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('next_scheduled_test');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    Hive.registerAdapter(ScheduleTypeAdapter());
    Hive.registerAdapter(PremadeHabitTypeAdapter());
    Hive.registerAdapter(HabitTrackingTypeAdapter());
    Hive.registerAdapter(HabitNotificationTimeAdapter());
    Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
    await Hive.openBox<Habit>('habits');
    await Hive.openBox<Day>('days');
  });

  setUp(() async {
    final today = _normalize(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _dayKey(today),
      'daySnapshotsSanitized_v1': true,
      'dateJoined': today.subtract(const Duration(days: 400)).toIso8601String(),
    });
    provider = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!provider.isInitialized) {
      if (DateTime.now().isAfter(deadline)) fail('init did not complete');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  final today = _normalize(DateTime.now());

  test('daily habit is next scheduled tomorrow', () {
    expect(
      provider.nextScheduledDate(_habit()),
      DateTime(today.year, today.month, today.day + 1),
    );
  });

  test('weekly habit on selected days finds the next one', () {
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final habit = _habit(
      scheduleType: ScheduleType.weekly,
      selectedDaysAWeek: [tomorrow.weekday],
    );
    expect(provider.nextScheduledDate(habit), tomorrow);

    // only today's weekday: next one is a week from today
    final sameWeekday = _habit(
      scheduleType: ScheduleType.weekly,
      selectedDaysAWeek: [today.weekday],
    );
    expect(
      provider.nextScheduledDate(sameWeekday),
      DateTime(today.year, today.month, today.day + 7),
    );
  });

  test('monthly habit on a day of the month finds the next one', () {
    final target = DateTime(today.year, today.month, today.day + 10);
    final habit = _habit(
      scheduleType: ScheduleType.monthly,
      selectedDaysAMonth: [target.day],
    );
    expect(provider.nextScheduledDate(habit), target);
  });

  test('from moves the starting day', () {
    final from = DateTime(today.year, today.month, today.day + 5);
    expect(
      provider.nextScheduledDate(_habit(), from: from),
      DateTime(today.year, today.month, today.day + 6),
    );
  });

  test('paused habit has no next date', () {
    expect(provider.nextScheduledDate(_habit(isPaused: true)), isNull);
  });
}
