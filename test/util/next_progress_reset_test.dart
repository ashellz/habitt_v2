import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/util/next_progress_reset.dart';

Habit _habit(ScheduleType type, {List<int>? weekDays, List<int>? monthDays}) =>
    Habit(
      id: 1,
      name: 'x',
      iconPath: '',
      categoryId: 0,
      scheduleType: type,
      selectedDaysAWeek: weekDays,
      selectedDaysAMonth: monthDays,
    );

void main() {
  final thursday = DateTime(2026, 10, 29);

  test('weekly target resets next Monday', () {
    expect(
      nextProgressReset(_habit(ScheduleType.weekly), thursday),
      DateTime(2026, 11, 2),
    );
    // on a Monday it is a full week away
    expect(
      nextProgressReset(_habit(ScheduleType.weekly), DateTime(2026, 11, 2)),
      DateTime(2026, 11, 9),
    );
    // Sunday: tomorrow
    expect(
      nextProgressReset(_habit(ScheduleType.weekly), DateTime(2026, 11, 1)),
      DateTime(2026, 11, 2),
    );
  });

  test('monthly target resets on the 1st of next month', () {
    expect(
      nextProgressReset(_habit(ScheduleType.monthly), thursday),
      DateTime(2026, 11, 1),
    );
    expect(
      nextProgressReset(_habit(ScheduleType.monthly), DateTime(2026, 12, 15)),
      DateTime(2027, 1, 1),
    );
  });

  test('no reset for fixed days, daily and custom', () {
    expect(
      nextProgressReset(_habit(ScheduleType.weekly, weekDays: [1]), thursday),
      isNull,
    );
    expect(
      nextProgressReset(_habit(ScheduleType.monthly, monthDays: [3]), thursday),
      isNull,
    );
    expect(nextProgressReset(_habit(ScheduleType.daily), thursday), isNull);
    expect(nextProgressReset(_habit(ScheduleType.custom), thursday), isNull);
  });
}
