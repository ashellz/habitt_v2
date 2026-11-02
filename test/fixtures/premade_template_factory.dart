import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/models/premade_habit_type.dart';

PremadeHabitTemplate buildTestTemplate({
  HealthMetricType? healthMetric,
  HealthWorkoutType? workoutFilter,
  int amount = 0,
  int durationMinutes = 0,
  int toleranceMinutes = 0,
  bool iosOnly = false,
}) {
  return PremadeHabitTemplate(
    type: PremadeHabitType.steps,
    name: 'Test',
    iconPath: '👟',
    categoryId: 1,
    amount: amount,
    durationMinutes: durationMinutes,
    defaultHealthMetric: healthMetric,
    defaultWorkoutFilter: workoutFilter,
    toleranceMinutes: toleranceMinutes,
    iosOnly: iosOnly,
  );
}
