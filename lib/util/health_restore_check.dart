import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';

/// The Health-linked habits of a restored backup, split by whether this
/// phone can read their metric. Nothing is unlinked either way: the others
/// keep their data and can still be edited by hand.
class HealthRestoreCheck {
  const HealthRestoreCheck({
    required this.trackable,
    required this.untrackable,
  });

  final List<Habit> trackable;
  final List<Habit> untrackable;

  bool get hasHealthHabits => trackable.isNotEmpty || untrackable.isNotEmpty;
}

HealthRestoreCheck checkRestoredHealthHabits(
  Iterable<Habit> habits, {
  required bool Function(HealthMetricType metric) canRead,
}) {
  final trackable = <Habit>[];
  final untrackable = <Habit>[];
  for (final habit in habits) {
    final metric = habit.healthMetric;
    if (metric == null || habit.isDeleted == true) continue;
    (canRead(metric) ? trackable : untrackable).add(habit);
  }
  return HealthRestoreCheck(trackable: trackable, untrackable: untrackable);
}
