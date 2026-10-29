import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';

/// The day a habit's weekly / monthly progress counter starts over, or null
/// when it has none: only habits with a "times a week / month" target count
/// progress per period. Habits on fixed days, daily and custom ones don't.
/// Weeks start on Monday.
DateTime? nextProgressReset(Habit habit, DateTime today) {
  switch (habit.scheduleType) {
    case ScheduleType.weekly:
      if (habit.selectedDaysAWeek.isNotEmpty) return null;
      return DateTime(today.year, today.month, today.day + 8 - today.weekday);
    case ScheduleType.monthly:
      if (habit.selectedDaysAMonth.isNotEmpty) return null;
      return DateTime(today.year, today.month + 1, 1);
    case ScheduleType.daily:
    case ScheduleType.custom:
      return null;
  }
}
