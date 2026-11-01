import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';

// Protects what is already recorded from a Health read that isn't real data.
// A normal read is always followed, even when it is lower than before (the
// user may have edited Health by hand). Only two kinds are thrown away:
//  - empty: 0 where the day already has progress. iOS can't report revoked
//    read access, it just answers with nothing, and Health Connect returns
//    nothing for days outside its readable window.
//  - corrupt: values no real day can have (negative, 400k steps, 30h of sleep).

/// What happened to one Health value handed to `syncHabitFromHealth`.
enum HealthApplyStatus {
  /// written (or the day was hand-edited and only its sessions were refreshed)
  applied,

  /// nothing to write: habit unlinked, or not on that day
  skipped,

  /// empty or corrupt, the existing data was kept
  discarded,
}

class HealthApplyOutcome {
  const HealthApplyOutcome(this.status, {this.completionChanged = false});

  final HealthApplyStatus status;

  /// the write flipped the day's completed flag
  final bool completionChanged;
}

const int _kMaxSteps = 200000;
const int _kMaxCalories = 20000;
const int _kMaxSleepMinutes = 24 * 60;
const int _kMaxDaySeconds = 24 * 60 * 60;
const int _kMaxSessionCount = 200;

/// Whether [value] is a number a real day could produce for [metric], in the
/// habit's native unit (see `HealthService.fetchValueForDay`).
/// [trackingType] matters for workouts/mindfulness, where the value is a
/// session count in Amount mode and seconds in Duration mode.
bool isPlausibleHealthValue(
  HealthMetricType metric,
  int value, {
  HabitTrackingType? trackingType,
}) {
  if (value < 0) return false;
  switch (metric) {
    case HealthMetricType.steps:
      return value <= _kMaxSteps;
    case HealthMetricType.activeCalories:
    case HealthMetricType.totalCalories:
      return value <= _kMaxCalories;
    case HealthMetricType.sleep:
      return value <= _kMaxSleepMinutes;
    case HealthMetricType.workouts:
    case HealthMetricType.mindfulness:
      return trackingType == HabitTrackingType.amount
          ? value <= _kMaxSessionCount
          : value <= _kMaxDaySeconds;
    case HealthMetricType.activity:
      return value <= _kMaxDaySeconds;
    case HealthMetricType.bedtime:
      // minutes since midnight, before noon counted as +24h (see HealthService)
      return value < 36 * 60;
    case HealthMetricType.wakeTime:
      return value < 24 * 60;
  }
}

/// Whether a Health read should be thrown away instead of written over what
/// the day already holds. [existing] is the day's current progress in the same
/// unit as [incoming].
bool shouldDiscardHealthValue(
  HealthMetricType metric,
  int incoming,
  int existing, {
  HabitTrackingType? trackingType,
}) {
  if (!isPlausibleHealthValue(metric, incoming, trackingType: trackingType)) {
    return true;
  }
  return incoming == 0 && existing > 0;
}

/// Whether two session lists describe the same Health sessions, so a sync can
/// tell a re-read that changed nothing from one that did. Compared by moment,
/// not by DateTime object (one side may be local, the other stored as UTC).
bool sameHealthSessions(
  List<HealthSessionDetail> a,
  List<HealthSessionDetail> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!a[i].start.isAtSameMomentAs(b[i].start) ||
        !a[i].end.isAtSameMomentAs(b[i].end) ||
        a[i].workoutType != b[i].workoutType) {
      return false;
    }
  }
  return true;
}
