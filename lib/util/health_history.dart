import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';

DateTime healthSyncDay(
  HealthMetricType metric,
  DateTime today, {
  bool bedtimeDayBefore = false,
}) {
  final dayStart = DateTime(today.year, today.month, today.day);
  if (metric == HealthMetricType.bedtime && bedtimeDayBefore) {
    return DateTime(dayStart.year, dayStart.month, dayStart.day - 1);
  }
  return dayStart;
}

// how a Health habit's progress is measured
// decides both the chart and how its numbers are written out
enum HealthHistoryKind {
  /// A count, e.g. steps, calories or workouts.
  amount,

  /// Seconds, e.g. workout or mindful time.
  duration,

  /// Minutes of sleep.
  sleepMinutes,

  /// Minutes since midnight, e.g. bedtime or wake time.
  timeOfDay,
}

/// One day of a Health habit's history.
class HealthDayPoint {
  final DateTime day;

  /// The day's progress in the unit of [HealthHistory.kind], or `null` when
  /// Health gave nothing for that day.
  final double? value;
  final bool completed;

  const HealthDayPoint({
    required this.day,
    required this.value,
    required this.completed,
  });
}

/// The last 7 days of a Health habit's progress against its target.
class HealthHistory {
  final HealthHistoryKind kind;
  final List<HealthDayPoint> points;

  /// The habit's target in the unit of [kind]; 0 when none is set.
  final double target;

  /// Extra minutes past [target] that still count as on time. Only
  /// [HealthHistoryKind.timeOfDay] uses it.
  final double tolerance;

  const HealthHistory({
    required this.kind,
    required this.points,
    required this.target,
    this.tolerance = 0,
  });

  bool get hasData => points.any((p) => p.value != null);
}

/// Reads [days] days of [habit]'s progress, ending on the day a sync run on
/// [today] writes to (see [healthSyncDay]). [habitForDay] returns the habit's
/// snapshot for a day, or `null` when the day has none.
HealthHistory buildHealthHistory(
  Habit habit,
  Habit? Function(DateTime day) habitForDay, {
  required DateTime today,
  int days = 7,
}) {
  final metric = habit.healthMetric;
  final end =
      metric == null
          ? DateTime(today.year, today.month, today.day)
          : healthSyncDay(
            metric,
            today,
            bedtimeDayBefore: habit.healthBedtimeDayBefore,
          );

  final HealthHistoryKind kind;
  final double target;
  if (habit.tracksTimeOfDay) {
    kind = HealthHistoryKind.timeOfDay;
    target = habit.amount.toDouble();
  } else if (habit.tracksDuration) {
    kind = HealthHistoryKind.duration;
    target = habit.duration.toDouble();
  } else if (metric == HealthMetricType.sleep) {
    kind = HealthHistoryKind.sleepMinutes;
    target = habit.amount.toDouble();
  } else {
    kind = HealthHistoryKind.amount;
    target = habit.amount.toDouble();
  }

  final points = <HealthDayPoint>[];
  for (var i = days - 1; i >= 0; i--) {
    final day = DateTime(end.year, end.month, end.day - i);
    final snapshot = habitForDay(day);
    points.add(
      HealthDayPoint(
        day: day,
        value: snapshot == null ? null : _valueOf(snapshot, kind),
        completed: snapshot?.completed ?? false,
      ),
    );
  }

  return HealthHistory(
    kind: kind,
    points: points,
    target: target,
    tolerance:
        kind == HealthHistoryKind.timeOfDay
            ? habit.effectiveToleranceMinutes.toDouble()
            : 0,
  );
}

double? _valueOf(Habit snapshot, HealthHistoryKind kind) {
  switch (kind) {
    case HealthHistoryKind.duration:
      return snapshot.durationCompleted.toDouble();
    case HealthHistoryKind.timeOfDay:
      // 0 is a reset day, not a midnight wake-up
      return snapshot.amountCompleted > 0
          ? snapshot.amountCompleted.toDouble()
          : null;
    case HealthHistoryKind.amount:
    case HealthHistoryKind.sleepMinutes:
      return snapshot.amountCompleted.toDouble();
  }
}
