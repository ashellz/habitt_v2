import 'package:habitt/models/habit.dart';
import 'package:habitt/util/get_duration_string.dart';

/// Habit-card text for a Health-linked sleep habit. Sleep is an amount habit
/// whose target and progress are in minutes, so it's shown as a duration
/// ("7h30m / 8h") instead of a raw number.
String getSleepAmountString(Habit habit) {
  String format(int minutes) => getDurationString(minutes * 60);

  final hasProgress = habit.amountCompleted > 0;
  if (hasProgress && !habit.completed) {
    return "${format(habit.amountCompleted)} / ${format(habit.amount)}";
  } else if (habit.completed) {
    return format(habit.amountCompleted);
  }
  return format(habit.amount);
}
