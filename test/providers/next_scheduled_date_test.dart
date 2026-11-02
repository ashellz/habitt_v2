import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/date_key.dart';
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
      'dateJoined': addCalendarDays(today, -400).toIso8601String(),
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

  group('nextAppearance', () {
    // "every 3 days" anchored 8 days ago: scheduled -8, -5, -2, +1, +4, ...
    Habit custom({bool completed = false}) {
      final anchor = addCalendarDays(today, -8);
      return Habit(
        id: 1,
        name: 'omega 3',
        iconPath: '',
        categoryId: 0,
        scheduleType: ScheduleType.custom,
        customIntervalDays: 3,
        showIfMissed: true,
        completed: completed,
        createdAt: addCalendarDays(today, -100),
        lastCustomUpdate: anchor,
        customAppearance: [
          for (var i = 0; i < 365; i += 3)
            _dayKey(addCalendarDays(anchor, i)),
        ],
      );
    }

    test('missed custom habit kept on by show if missed is today', () {
      expect(provider.nextAppearance(custom()), today);
    });

    test('once completed it points at the next scheduled day', () {
      expect(
        provider.nextAppearance(custom(completed: true)),
        DateTime(today.year, today.month, today.day + 1),
      );
    });

    test('paused habit has none', () {
      expect(provider.nextAppearance(_habit(isPaused: true)), isNull);
    });

    test('daily habit still to do is today', () {
      expect(provider.nextAppearance(_habit()), today);
    });
  });

  group('custom schedule extension', () {
    // Grid anchored 201 days ago (so today is on it), stored for only 180
    // days, last rebuilt 5 days ago. Extending must continue the grid, not
    // restart it from the last-update day (which would put it on tomorrow).
    Habit expired() {
      final anchor = addCalendarDays(today, -201);
      return Habit(
        id: 1,
        name: 'stretch',
        iconPath: '',
        categoryId: 0,
        scheduleType: ScheduleType.custom,
        customIntervalDays: 3,
        createdAt: addCalendarDays(today, -300),
        lastCustomUpdate: addCalendarDays(today, -5).toUtc(),
        customAppearance: [
          for (var i = 0; i < 180; i += 3) _dayKey(addCalendarDays(anchor, i)),
        ],
      );
    }

    test('continues the stored grid once it runs out', () {
      final habit = expired();
      expect(provider.appearsOnDay(habit, today), isTrue);
      expect(provider.appearsOnDay(habit, addCalendarDays(today, 1)), isFalse);
      expect(provider.appearsOnDay(habit, addCalendarDays(today, 2)), isFalse);
      expect(provider.appearsOnDay(habit, addCalendarDays(today, 3)), isTrue);
    });

    test('extended list stays evenly spaced and bounded', () {
      final habit = expired();
      provider.appearsOnDay(habit, today);
      final keys = habit.customAppearance;
      for (var i = 1; i < keys.length; i++) {
        expect(
          calendarDaysBetween(
            DateTime.parse(keys[i - 1]),
            DateTime.parse(keys[i]),
          ),
          3,
        );
      }
      // keeps about a year of past dates, plus a year ahead
      expect(
        keys.first.compareTo(_dayKey(addCalendarDays(today, -366))) >= 0,
        isTrue,
      );
      expect(
        keys.last.compareTo(_dayKey(addCalendarDays(today, 362))) >= 0,
        isTrue,
      );
    });
  });
}
