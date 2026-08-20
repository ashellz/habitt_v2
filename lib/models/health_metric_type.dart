import 'package:habitt/models/habit.dart';

/// Which Health data source drives a habit's progress, when linked.
enum HealthMetricType {
  steps,
  sleep,
  exerciseMinutes,
  mindfulMinutes,
  activeCalories,
  totalCalories,
}

extension HealthMetricTypeMapping on HealthMetricType {
  /// Steps are a count goal; everything else is a duration goal (seconds).
  HabitTrackingType get trackingType =>
      this == HealthMetricType.steps ||
              this == HealthMetricType.activeCalories ||
              this == HealthMetricType.totalCalories
          ? HabitTrackingType.amount
          : HabitTrackingType.duration;
}
