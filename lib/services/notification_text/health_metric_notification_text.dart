import 'dart:math' as math;

import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/services/notification_text/sleep_notification_text.dart';
import 'package:habitt/services/notification_text/types.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
import 'package:intl/intl.dart';

/// Notification wording for the Health-linked activity habits: steps, active
/// and total calories, workouts (with the specific activity) and mindfulness.
/// Numbers get thousands separators and durations are spoken, so a 90 minute
/// workout reads "1 hour and 30 minutes" instead of a raw count.
class HealthMetricNotificationText {
  /// The Health metric this habit's notification should talk about, or null
  /// when the habit isn't one of the supported activity habits.
  static HealthMetricType? metricFor(Habit habit) {
    final metric = habit.healthMetric ?? _metricFromPremade(habit);
    switch (metric) {
      case HealthMetricType.steps:
      case HealthMetricType.activeCalories:
      case HealthMetricType.totalCalories:
        return habit.tracksAmount && habit.amount > 0 ? metric : null;
      case HealthMetricType.workouts:
        final hasGoal =
            habit.tracksDuration ? habit.duration > 0 : habit.amount > 0;
        return (habit.tracksDuration || habit.tracksAmount) && hasGoal
            ? metric
            : null;
      case HealthMetricType.mindfulness:
        return habit.tracksDuration && habit.duration > 0 ? metric : null;
      default:
        return null;
    }
  }

  static HealthMetricType? _metricFromPremade(Habit habit) {
    switch (habit.premadeHabitType) {
      case PremadeHabitType.steps:
        return HealthMetricType.steps;
      case PremadeHabitType.activeCalories:
        return HealthMetricType.activeCalories;
      case PremadeHabitType.totalCalories:
        return HealthMetricType.totalCalories;
      case PremadeHabitType.mindfulness:
        return HealthMetricType.mindfulness;
      case PremadeHabitType.workoutCombined:
      case PremadeHabitType.workoutWalking:
      case PremadeHabitType.workoutRunning:
      case PremadeHabitType.workoutCycling:
      case PremadeHabitType.workoutSwimming:
      case PremadeHabitType.workoutHiking:
      case PremadeHabitType.workoutFlexibility:
      case PremadeHabitType.workoutDancing:
      case PremadeHabitType.workoutRowing:
        return HealthMetricType.workouts;
      default:
        return null;
    }
  }

  /// Description for the habit's notification, or null to use the regular
  /// templates (not an activity habit, or today's goal is already reached).
  static String? build(
    HabitNotificationContext context, {
    math.Random? random,
    Map<String, String>? customSingulars,
  }) {
    final habit = context.habit;
    final metric = metricFor(habit);
    if (metric == null) return null;

    final l = context.localizations;
    final rng = random ?? math.Random();
    final measure = _Measure.of(
      habit,
      metric,
      l,
      customSingulars ?? context.customSingulars,
    );
    if (measure.goal <= 0 || measure.done >= measure.goal) return null;

    // the text is fixed when the notification is scheduled, but Health only
    // syncs on app open, so a Health-linked habit's progress can be hours out
    // of date by the time this fires ("6 of 230" after a long workout). Only
    // hand-logged progress, which is always current, is worth quoting.
    final started = habit.healthMetric == null && measure.done > 0;
    final goalText = measure.format(measure.goal);
    final progressText = measure.format(measure.done);
    final remainingText = measure.format(measure.goal - measure.done);

    switch (metric) {
      case HealthMetricType.steps:
        return _pick(
          started
              ? l.notificationHealthStepsProgress(progressText, remainingText)
              : l.notificationHealthStepsStart(goalText),
          rng,
        );
      case HealthMetricType.activeCalories:
        return _pick(
          started
              ? l.notificationHealthActiveCaloriesProgress(
                progressText,
                remainingText,
              )
              : l.notificationHealthActiveCaloriesStart(goalText),
          rng,
        );
      case HealthMetricType.totalCalories:
        return _pick(
          started
              ? l.notificationHealthTotalCaloriesProgress(
                progressText,
                remainingText,
              )
              : l.notificationHealthTotalCaloriesStart(goalText),
          rng,
        );
      case HealthMetricType.mindfulness:
        return _pick(
          started
              ? l.notificationHealthMindfulnessProgress(
                progressText,
                remainingText,
              )
              : l.notificationHealthMindfulnessStart(goalText),
          rng,
        );
      case HealthMetricType.workouts:
        return _workout(
          l,
          habit,
          started: started,
          goalText: goalText,
          progressText: progressText,
          remainingText: remainingText,
          rng: rng,
        );
      default:
        return null;
    }
  }

  static String _workout(
    AppLocalizations l,
    Habit habit, {
    required bool started,
    required String goalText,
    required String progressText,
    required String remainingText,
    required math.Random rng,
  }) {
    final activity = habit.healthWorkoutFilter ?? _workoutFromPremade(habit);
    final activityLabel = activity.label(l);

    if (started) {
      return _pick(
        l.notificationHealthWorkoutProgress(
          activityLabel,
          progressText,
          remainingText,
        ),
        rng,
      );
    }

    // specific activities also get a short nudge in the mix
    final options = _options(
      l.notificationHealthWorkoutStart(activityLabel, goalText),
    );
    final nudge = _nudge(l, activity);
    if (nudge != null) options.addAll(_options(nudge));
    return options[rng.nextInt(options.length)];
  }

  static HealthWorkoutType? _workoutFromPremade(Habit habit) {
    switch (habit.premadeHabitType) {
      case PremadeHabitType.workoutWalking:
        return HealthWorkoutType.walking;
      case PremadeHabitType.workoutRunning:
        return HealthWorkoutType.running;
      case PremadeHabitType.workoutCycling:
        return HealthWorkoutType.cycling;
      case PremadeHabitType.workoutSwimming:
        return HealthWorkoutType.swimming;
      case PremadeHabitType.workoutHiking:
        return HealthWorkoutType.hiking;
      case PremadeHabitType.workoutFlexibility:
        return HealthWorkoutType.flexibility;
      case PremadeHabitType.workoutDancing:
        return HealthWorkoutType.dancing;
      case PremadeHabitType.workoutRowing:
        return HealthWorkoutType.rowing;
      default:
        return null;
    }
  }

  static String? _nudge(AppLocalizations l, HealthWorkoutType? activity) {
    switch (activity) {
      case HealthWorkoutType.walking:
        return l.notificationHealthNudgeWalking;
      case HealthWorkoutType.running:
        return l.notificationHealthNudgeRunning;
      case HealthWorkoutType.cycling:
        return l.notificationHealthNudgeCycling;
      case HealthWorkoutType.swimming:
        return l.notificationHealthNudgeSwimming;
      case HealthWorkoutType.hiking:
        return l.notificationHealthNudgeHiking;
      case HealthWorkoutType.flexibility:
        return l.notificationHealthNudgeFlexibility;
      case HealthWorkoutType.dancing:
        return l.notificationHealthNudgeDancing;
      case HealthWorkoutType.rowing:
        return l.notificationHealthNudgeRowing;
      case HealthWorkoutType.other:
      case null:
        return null;
    }
  }

  // variants are pipe-separated in the ARB files
  static List<String> _options(String value) {
    final options =
        value
            .split('|')
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
    return options.isEmpty ? [value] : options;
  }

  static String _pick(String value, math.Random rng) {
    final options = _options(value);
    return options[rng.nextInt(options.length)];
  }
}

/// A habit's goal and progress in one unit, with a way to say a value out
/// loud: spoken minutes for durations, "6,000 steps" for counts.
class _Measure {
  _Measure({required this.goal, required this.done, required this.format});

  final int goal;
  final int done;
  final String Function(int value) format;

  static _Measure of(
    Habit habit,
    HealthMetricType metric,
    AppLocalizations l,
    Map<String, String>? customSingulars,
  ) {
    final isDuration =
        metric == HealthMetricType.mindfulness ||
        (metric == HealthMetricType.workouts && habit.tracksDuration);

    if (isDuration) {
      // durations are stored in seconds; remaining time rounds up so a
      // notification never says "0 minutes left"
      int minutes(int seconds) => math.max(1, (seconds / 60).ceil());
      return _Measure(
        goal: habit.duration,
        done: habit.durationCompleted,
        format:
            (seconds) =>
                SleepNotificationText.formatSleepDuration(l, minutes(seconds)),
      );
    }

    final numbers = _numberFormat(l);
    final label = _labelFor(habit, metric);
    return _Measure(
      goal: habit.amount,
      done: habit.amountCompleted,
      format: (value) {
        final unit = resolveAmountLabelForValue(
          label,
          value,
          l,
          customSingulars: customSingulars,
        );
        return '${numbers(value)} $unit'.trim();
      },
    );
  }

  // steps and calories habits that kept the generic "times" label would read
  // "6,000 times", so they fall back to their metric's own unit
  static String _labelFor(Habit habit, HealthMetricType metric) {
    final label = habit.amountLabel.trim();
    final isGeneric =
        label.isEmpty ||
        label.toLowerCase() == AmountLabelPreset.times.plural ||
        label.toLowerCase() == AmountLabelPreset.times.singular;
    if (!isGeneric) return label;

    switch (metric) {
      case HealthMetricType.steps:
        return AmountLabelPreset.steps.plural;
      case HealthMetricType.activeCalories:
      case HealthMetricType.totalCalories:
        return AmountLabelPreset.calories.plural;
      default:
        return label.isEmpty ? AmountLabelPreset.times.plural : label;
    }
  }

  static String Function(int) _numberFormat(AppLocalizations l) {
    try {
      return NumberFormat.decimalPattern(l.localeName).format;
    } catch (_) {
      return (value) => value.toString();
    }
  }
}
