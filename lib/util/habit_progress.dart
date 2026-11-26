import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/get_sleep_amount_string.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';

/// How far past target + tolerance the pie stays empty for timeOfDay habits.
const int timeOfDayProgressWindowMinutes = 240;

/// Progress of [habit] from 0 to 1, as the habit card's pie shows it.
/// Shared by the habit card ([NewHabitProgress]) and the home screen widgets
/// so both always agree. [liveDurationSeconds] is a running timer's value.
double habitProgressValue(Habit habit, {int? liveDurationSeconds}) {
  if (habit.completed || habit.skipped) return 1.0;

  // timeOfDay (bedtime/wake time): earlier is better, values are minutes of
  // day. Nothing logged = no progress; otherwise the pie fills as the logged
  // time gets closer to target + tolerance (completed is handled above).
  if (habit.tracksTimeOfDay) {
    if (habit.amountCompleted <= 0) return 0.0;
    final lateness =
        habit.amountCompleted - (habit.amount + habit.toleranceMinutes);
    if (lateness <= 0) return 1.0;
    return (1 - lateness / timeOfDayProgressWindowMinutes).clamp(0.0, 1.0);
  }

  if (habit.tracksAmount) {
    if (habit.effectiveAmount <= 0) return 0.0; // avoiding division by zero
    final progress = habit.amountCompleted / habit.effectiveAmount;
    return progress.clamp(0.0, 1.0);
  }

  if (habit.tracksDuration) {
    // use timer progress if available, otherwise use the habits completed duration
    if (habit.effectiveDuration <= 0) return 0.0; // avoiding division by zero
    final completed = liveDurationSeconds ?? habit.durationCompleted;
    final progress = completed / habit.effectiveDuration;
    return progress.clamp(0.0, 1.0);
  }

  return 0.0;
}

/// The progress line under a habit's name on the habit card ("8m / 10m",
/// "2 / 8 glasses", a clock time), or "" for a habit with no tracking type.
/// [formatTime] formats minutes since midnight as a clock time.
String habitProgressText(
  Habit habit, {
  required AppLocalizations loc,
  required Map<String, String> customSingulars,
  required String Function(int minutes) formatTime,
  int? liveDurationSeconds,
}) {
  final int durationCompletedValue =
      liveDurationSeconds ?? habit.durationCompleted;
  final bool hasProgress =
      habit.tracksAmount || habit.tracksTimeOfDay
          ? habit.amountCompleted > 0
          : durationCompletedValue > 0;
  final bool isCompleted = habit.completed;

  String amountText() {
    if (habit.healthMetric == HealthMetricType.sleep) {
      return getSleepAmountString(habit);
    }
    final int amountForLabel =
        hasProgress && !isCompleted
            ? habit.effectiveAmount
            : (isCompleted ? habit.amountCompleted : habit.effectiveAmount);
    final String amountLabel = resolveAmountLabelForValue(
      habit.amountLabel.isEmpty
          ? AmountLabelPreset.times.plural
          : habit.amountLabel,
      amountForLabel,
      loc,
      customSingulars: customSingulars,
    );

    if (hasProgress && !isCompleted) {
      return "${habit.amountCompleted} / ${habit.effectiveAmount} $amountLabel";
    } else if (isCompleted) {
      return "${habit.amountCompleted} $amountLabel";
    }
    return "${habit.effectiveAmount} $amountLabel";
  }

  String durationText() {
    if ((hasProgress && !isCompleted) &&
        durationCompletedValue < habit.effectiveDuration) {
      return "${getDurationString(durationCompletedValue)} / ${getDurationString(habit.effectiveDuration)}";
    } else if (isCompleted || durationCompletedValue >= habit.effectiveDuration) {
      return getDurationString(durationCompletedValue);
    }
    return getDurationString(habit.effectiveDuration);
  }

  switch (habit.trackingType) {
    case HabitTrackingType.amount:
      return amountText();
    case HabitTrackingType.duration:
      return durationText();
    case HabitTrackingType.timeOfDay:
      // the real logged bedtime or wake time once there is one, otherwise the target
      return formatTime(hasProgress ? habit.amountCompleted : habit.amount);
    default:
      return "";
  }
}
