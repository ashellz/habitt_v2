import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';

enum HealthMetricType {
  steps, // track steps only
  sleep, // sleep amount + tolerance
  workouts,
  mindfulness,
  activeCalories,
  totalCalories,
  bedtime,
  wakeTime,
}

extension HealthMetricTypeMapping on HealthMetricType {
  /// Workouts and mindfulness let the user choose between Amount (a session
  /// count) and Duration (summed minutes) tracking — every other metric's
  /// tracking type is fixed by [trackingType].
  bool get supportsTrackingChoice =>
      this == HealthMetricType.workouts || this == HealthMetricType.mindfulness;

  HabitTrackingType get trackingType {
    switch (this) {
      case HealthMetricType.steps:
      case HealthMetricType.activeCalories:
      case HealthMetricType.totalCalories:
      case HealthMetricType.sleep:
        return HabitTrackingType.amount;
      case HealthMetricType.workouts:
      case HealthMetricType.mindfulness:
        return HabitTrackingType.duration;
      case HealthMetricType.bedtime:
      case HealthMetricType.wakeTime:
        return HabitTrackingType.timeOfDay;
    }
  }

  String get iconPath {
    switch (this) {
      case HealthMetricType.steps:
        return 'assets/images/health-icons/steps.png';
      case HealthMetricType.sleep:
        return 'assets/images/health-icons/sleep.png';
      case HealthMetricType.workouts:
        return 'assets/images/health-icons/workout.png';
      case HealthMetricType.mindfulness:
        return 'assets/images/health-icons/mindfullnes.png';
      case HealthMetricType.activeCalories:
        return 'assets/images/health-icons/burned_calories.png';
      case HealthMetricType.totalCalories:
        return 'assets/images/health-icons/total_calories.png';
      case HealthMetricType.bedtime:
        return 'assets/images/health-icons/bedtime.png';
      case HealthMetricType.wakeTime:
        return 'assets/images/health-icons/wake.png';
    }
  }

  String label(AppLocalizations loc) {
    switch (this) {
      case HealthMetricType.steps:
        return loc.healthMetricSteps;
      case HealthMetricType.sleep:
        return loc.healthMetricSleep;
      case HealthMetricType.workouts:
        return loc.premadeHabitWorkoutCombined;
      case HealthMetricType.mindfulness:
        return loc.healthMetricMindfulMinutes;
      case HealthMetricType.activeCalories:
        return loc.healthMetricActiveCalories;
      case HealthMetricType.totalCalories:
        return loc.healthMetricTotalCalories;
      case HealthMetricType.bedtime:
        return loc.healthTargetBedtime;
      case HealthMetricType.wakeTime:
        return loc.healthTargetWakeTime;
    }
  }

  String desc(AppLocalizations loc) {
    switch (this) {
      case HealthMetricType.steps:
        return loc.healthMetricDescSteps;
      case HealthMetricType.sleep:
        return loc.healthMetricDescSleep;
      case HealthMetricType.workouts:
        return loc.healthMetricDescWorkouts;
      case HealthMetricType.mindfulness:
        return loc.healthMetricDescMindfulness;
      case HealthMetricType.activeCalories:
        return loc.healthMetricDescActiveCalories;
      case HealthMetricType.totalCalories:
        return loc.healthMetricDescTotalCalories;
      case HealthMetricType.bedtime:
        return loc.healthMetricDescBedtime;
      case HealthMetricType.wakeTime:
        return loc.healthMetricDescWakeTime;
    }
  }
}
