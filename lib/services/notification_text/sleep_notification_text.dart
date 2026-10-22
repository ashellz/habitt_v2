import 'dart:math' as math;

import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/services/notification_text/types.dart';

// how far ahead of bedtime a reminder still counts as "bedtime is in X"
const int _bedtimeSoonWindowMinutes = 3 * 60;

/// Notification wording for the Health-linked sleep habits (sleep time,
/// bedtime and wake time). Their values are minutes (a duration, or a time of
/// day), so the generic amount templates would read "61 times".
class SleepNotificationText {
  /// The sleep metric this habit's notification should talk about, or null
  /// when the habit isn't one of the three sleep habits.
  static HealthMetricType? metricFor(Habit habit) {
    final metric = habit.healthMetric ?? _metricFromPremade(habit);
    switch (metric) {
      case HealthMetricType.bedtime:
      case HealthMetricType.wakeTime:
        return habit.tracksTimeOfDay && habit.amount > 0 ? metric : null;
      case HealthMetricType.sleep:
        return habit.tracksAmount && habit.amount > 0 ? metric : null;
      default:
        return null;
    }
  }

  static HealthMetricType? _metricFromPremade(Habit habit) {
    switch (habit.premadeHabitType) {
      case PremadeHabitType.goToBedEarly:
        return HealthMetricType.bedtime;
      case PremadeHabitType.wakeUpEarly:
        return HealthMetricType.wakeTime;
      case PremadeHabitType.sleepTime:
        return HealthMetricType.sleep;
      default:
        return null;
    }
  }

  /// Description for a sleep habit's notification, or null to use the regular
  /// templates.
  static String? build(
    HabitNotificationContext context, {
    math.Random? random,
  }) {
    final habit = context.habit;
    final metric = metricFor(habit);
    if (metric == null) return null;

    final l = context.localizations;
    final rng = random ?? math.Random();

    switch (metric) {
      case HealthMetricType.bedtime:
        return _bedtime(context, rng);
      case HealthMetricType.wakeTime:
        return _pick(
          l.notificationSleepWakeUp(formatClock(l, habit.amount)),
          rng,
        );
      case HealthMetricType.sleep:
        return _sleepGoal(context, rng);
      default:
        return null;
    }
  }

  static String _bedtime(HabitNotificationContext context, math.Random rng) {
    final l = context.localizations;
    final habit = context.habit;
    final time = formatClock(l, habit.amount);

    final scheduledMinutes =
        context.scheduledAt.hour * 60 + context.scheduledAt.minute;
    final untilBedtime = ((habit.amount % 1440) - scheduledMinutes) % 1440;

    if (untilBedtime > 0 && untilBedtime <= _bedtimeSoonWindowMinutes) {
      return _pick(
        l.notificationSleepBedtimeSoon(
          formatSleepDuration(l, untilBedtime),
          time,
        ),
        rng,
      );
    }
    return _pick(l.notificationSleepBedtime(time), rng);
  }

  static String _sleepGoal(HabitNotificationContext context, math.Random rng) {
    final l = context.localizations;
    final habit = context.habit;
    final goal = formatSleepDuration(l, habit.amount);

    // Health-linked progress is stale by the time the notification fires (it
    // only syncs on app open), so only hand-logged sleep is quoted
    if (habit.healthMetric == null &&
        habit.amountCompleted > 0 &&
        habit.amountCompleted < habit.amount) {
      return _pick(
        l.notificationSleepGoalProgress(
          formatSleepDuration(l, habit.amountCompleted),
          goal,
        ),
        rng,
      );
    }
    return _pick(l.notificationSleepGoal(goal), rng);
  }

  /// Minutes as a spoken duration: "15 minutes", "1 hour", "1 hour and 30
  /// minutes".
  static String formatSleepDuration(AppLocalizations l, int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;

    if (hours > 0 && remainder > 0) {
      return l.notificationSleepHoursAndMinutes(
        l.notificationSleepHours(hours),
        l.notificationSleepMinutes(remainder),
      );
    }
    if (hours > 0) return l.notificationSleepHours(hours);
    return l.notificationSleepMinutes(remainder);
  }

  /// Minutes since midnight as a clock time. English uses 12-hour with AM/PM,
  /// the other app languages use 24-hour. Bedtimes stored past 1440 wrap.
  static String formatClock(AppLocalizations l, int minutesOfDay) {
    final normalized = minutesOfDay % 1440;
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    final mm = minute.toString().padLeft(2, '0');

    if (l.localeName.startsWith('en')) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$hour12:$mm $period';
    }
    return '${hour.toString().padLeft(2, '0')}:$mm';
  }

  // variants are pipe-separated in the ARB files
  static String _pick(String value, math.Random rng) {
    final options =
        value
            .split('|')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
    if (options.isEmpty) return value;
    return options[rng.nextInt(options.length)];
  }
}
