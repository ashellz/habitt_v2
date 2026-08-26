import 'dart:io';

import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Thin, read-only wrapper around the `health` plugin (Apple HealthKit /
/// Google Health Connect). Isolates the plugin's API surface from the rest
/// of the app — nothing outside this file should import `package:health`.
///
/// On Android, step/fitness data sits on top of the classic OS-level
/// `ACTIVITY_RECOGNITION` runtime permission — Health Connect's own consent
/// screen (driven by [Health.requestAuthorization]) does not request this;
/// per the `health` package's own docs it must be requested separately via
/// `permission_handler` before requesting Health Connect access. iOS has no
/// equivalent — HealthKit doesn't use classic Android-style runtime
/// permissions, so `permission_handler` is never used there.
///
/// Time-of-day values (bedtime/wake time) are minutes-since-midnight, with
/// one convention: any wall-clock time before noon is treated as "the small
/// hours of the same night" and gets +1440 added, so a 1:00 AM bedtime
/// (1500) still sorts later than an 11:00 PM one (1380). This mirrors the
/// noon-to-noon window already used for sleep queries. Wake times don't
/// need this — they're always compared as plain minutes-since-midnight.
class HealthService {
  HealthService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  // Health Connect has no mindfulness record type. bedtime/wakeTime reuse
  // the same sleep types as `sleep` — same read, different aggregation.
  static const Map<HealthMetricType, List<HealthDataType>> _iosTypes = {
    HealthMetricType.steps: [HealthDataType.STEPS],
    HealthMetricType.sleep: [HealthDataType.SLEEP_ASLEEP],
    HealthMetricType.bedtime: [HealthDataType.SLEEP_ASLEEP],
    HealthMetricType.wakeTime: [HealthDataType.SLEEP_ASLEEP],
    HealthMetricType.workouts: [HealthDataType.EXERCISE_TIME],
    HealthMetricType.mindfulness: [HealthDataType.MINDFULNESS],
    HealthMetricType.activeCalories: [HealthDataType.ACTIVE_ENERGY_BURNED],
    HealthMetricType.totalCalories: [HealthDataType.TOTAL_CALORIES_BURNED],
  };

  static const Map<HealthMetricType, List<HealthDataType>> _androidTypes = {
    HealthMetricType.steps: [HealthDataType.STEPS],
    HealthMetricType.sleep: [HealthDataType.SLEEP_ASLEEP],
    HealthMetricType.bedtime: [HealthDataType.SLEEP_ASLEEP],
    HealthMetricType.wakeTime: [HealthDataType.SLEEP_ASLEEP],
    HealthMetricType.workouts: [HealthDataType.WORKOUT],
    HealthMetricType.activeCalories: [HealthDataType.ACTIVE_ENERGY_BURNED],
    HealthMetricType.totalCalories: [HealthDataType.TOTAL_CALORIES_BURNED],
  };

  // amount-tracked metrics — their HealthDataPoint.value is a plain count
  // (steps, kilocalories) rather than something duration-shaped.
  static const Set<HealthMetricType> _countMetrics = {
    HealthMetricType.steps,
    HealthMetricType.activeCalories,
    HealthMetricType.totalCalories,
  };

  // Metrics whose underlying samples carry sessions worth listing
  // individually (as opposed to steps/calories, which are just a running
  // count with no meaningful "session").
  static const Set<HealthMetricType> _sessionMetrics = {
    HealthMetricType.workouts,
    HealthMetricType.mindfulness,
    HealthMetricType.sleep,
    HealthMetricType.bedtime,
    HealthMetricType.wakeTime,
  };

  // workouts and mindfulness both let the user choose between summed
  // duration and a plain session count for the day.
  static const Set<HealthMetricType> _dualModeMetrics = {
    HealthMetricType.workouts,
    HealthMetricType.mindfulness,
  };

  static const Map<HealthWorkoutType, List<HealthWorkoutActivityType>>
  _workoutTypeMap = {
    HealthWorkoutType.walking: [HealthWorkoutActivityType.WALKING],
    HealthWorkoutType.running: [
      HealthWorkoutActivityType.RUNNING,
      HealthWorkoutActivityType.RUNNING_TREADMILL,
    ],
    HealthWorkoutType.cycling: [
      HealthWorkoutActivityType.BIKING,
      HealthWorkoutActivityType.BIKING_STATIONARY,
    ],
    HealthWorkoutType.swimming: [HealthWorkoutActivityType.SWIMMING],
    HealthWorkoutType.hiking: [HealthWorkoutActivityType.HIKING],
    HealthWorkoutType.flexibility: [
      HealthWorkoutActivityType.YOGA,
      HealthWorkoutActivityType.PILATES,
      HealthWorkoutActivityType.FLEXIBILITY,
      HealthWorkoutActivityType.MIND_AND_BODY,
    ],
    HealthWorkoutType.dancing: [
      HealthWorkoutActivityType.CARDIO_DANCE,
      HealthWorkoutActivityType.SOCIAL_DANCE,
      HealthWorkoutActivityType.DANCING,
    ],
    HealthWorkoutType.rowing: [
      HealthWorkoutActivityType.ROWING,
      HealthWorkoutActivityType.ROWING_MACHINE,
    ],
  };

  static HealthWorkoutType _mapWorkoutActivityType(
    HealthWorkoutActivityType type,
  ) {
    for (final entry in _workoutTypeMap.entries) {
      if (entry.value.contains(type)) return entry.key;
    }
    return HealthWorkoutType.other;
  }

  Map<HealthMetricType, List<HealthDataType>> get _typesByMetric =>
      Platform.isAndroid ? _androidTypes : _iosTypes;

  /// Metrics that can be linked to a habit on this platform.
  List<HealthMetricType> get supportedMetrics => _typesByMetric.keys.toList();

  bool isMetricSupported(HealthMetricType metric) =>
      _typesByMetric.containsKey(metric);

  List<HealthDataType> get _allTypes =>
      _typesByMetric.values.expand((types) => types).toSet().toList();

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Whether Health data can be read on this device at all (HealthKit is
  /// always considered available on iOS; on Android this checks whether the
  /// Health Connect app is installed).
  Future<bool> isAvailable() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    await _ensureConfigured();
    return _health.isHealthConnectAvailable();
  }

  Future<bool> hasPermissions() async {
    await _ensureConfigured();
    final granted = await _health.hasPermissions(
      _allTypes,
      permissions: List.filled(_allTypes.length, HealthDataAccess.READ),
    );
    return granted ?? false;
  }

  /// Requests read-only access to every Health metric Habitt uses.
  Future<bool> requestAuthorization() async {
    await _ensureConfigured();

    if (Platform.isAndroid) {
      // Doesn't gate on the result — sleep/exercise/calories don't depend
      // on this permission, so a denial here shouldn't block requesting
      // those. A denied ACTIVITY_RECOGNITION just means steps reads come
      // back empty afterwards, which fetchValueForDay already handles.
      await ph.Permission.activityRecognition.request();
    }

    return _health.requestAuthorization(
      _allTypes,
      permissions: List.filled(_allTypes.length, HealthDataAccess.READ),
    );
  }

  /// The type(s) to query for [metric]. Workout habits filtered to one
  /// [workoutFilter] query `WORKOUT` (which carries an activity type) even
  /// on iOS, where an unfiltered workout habit would otherwise use the
  /// type-less `EXERCISE_TIME` quantity.
  List<HealthDataType> _queryTypesFor(
    HealthMetricType metric,
    HealthWorkoutType? workoutFilter,
  ) {
    if (metric == HealthMetricType.workouts &&
        Platform.isIOS &&
        workoutFilter != null) {
      return [HealthDataType.WORKOUT];
    }
    return _typesByMetric[metric] ?? const [];
  }

  Future<List<HealthDataPoint>> _fetchPoints(
    HealthMetricType metric,
    DateTime day,
    HealthWorkoutType? workoutFilter,
  ) async {
    final window = _windowFor(metric, day);
    final types = _queryTypesFor(metric, workoutFilter);
    if (types.isEmpty) return const [];

    final points = await _health.getHealthDataFromTypes(
      types: types,
      startTime: window.start,
      endTime: window.end,
    );

    if (metric != HealthMetricType.workouts || workoutFilter == null) {
      return points;
    }

    return points.where((point) {
      final value = point.value;
      if (value is! WorkoutHealthValue) return false;
      return _mapWorkoutActivityType(value.workoutActivityType) ==
          workoutFilter;
    }).toList();
  }

  /// The value for [metric] on the calendar [day], in the habit's native
  /// unit — a raw count for [HealthMetricType.steps]/calories, seconds for
  /// duration-tracked metrics, minutes-since-midnight for [bedtime]/
  /// [wakeTime]. Returns `null` if the metric isn't supported on this
  /// platform or the read fails.
  ///
  /// [trackingType] only matters for [HealthMetricType.workouts] and
  /// [HealthMetricType.mindfulness]: a habit tracking `amount` gets the
  /// session *count* for the day instead of summed duration — same
  /// underlying read, different aggregation. [workoutFilter] narrows
  /// workout reads to one [HealthWorkoutType].
  Future<int?> fetchValueForDay(
    HealthMetricType metric,
    DateTime day, {
    HabitTrackingType? trackingType,
    HealthWorkoutType? workoutFilter,
  }) async {
    if (!isMetricSupported(metric)) return null;

    try {
      await _ensureConfigured();

      if (metric == HealthMetricType.steps) {
        final start = DateTime(day.year, day.month, day.day);
        final end = start.add(const Duration(days: 1));
        return _health.getTotalStepsInInterval(start, end);
      }

      final points = await _fetchPoints(metric, day, workoutFilter);

      if (_countMetrics.contains(metric)) {
        final total = points.fold<double>(0, (sum, point) {
          final value = point.value;
          return value is NumericHealthValue
              ? sum + value.numericValue.toDouble()
              : sum;
        });
        return total.round();
      }

      if (metric == HealthMetricType.bedtime) {
        if (points.isEmpty) return null;
        final earliest = points
            .map((p) => p.dateFrom)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        return _bedtimeMinutesOfDay(earliest);
      }

      if (metric == HealthMetricType.wakeTime) {
        if (points.isEmpty) return null;
        final latest = points
            .map((p) => p.dateTo)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        return latest.hour * 60 + latest.minute;
      }

      if (_dualModeMetrics.contains(metric) &&
          trackingType == HabitTrackingType.amount) {
        return points.length;
      }

      if (Platform.isAndroid && metric == HealthMetricType.workouts) {
        // Workout sessions carry no duration value on Health Connect —
        // derive it from each session's start/end instead.
        return points.fold<int>(
          0,
          (sum, point) =>
              sum + point.dateTo.difference(point.dateFrom).inSeconds,
        );
      }

      // Sleep / exercise-time / mindfulness samples are declared in MINUTE
      // units by the plugin, so their numeric value is already a duration.
      final totalMinutes = points.fold<double>(0, (sum, point) {
        final value = point.value;
        if (value is NumericHealthValue) {
          return sum + value.numericValue.toDouble();
        }
        return sum;
      });
      return (totalMinutes * 60).round();
    } catch (_) {
      return null;
    }
  }

  /// The individual sessions behind [fetchValueForDay]'s summed/counted
  /// value — for display (which workout, what time range), not for
  /// completion math. Returns an empty list for metrics with no session
  /// concept (steps, calories) or on any read failure.
  Future<List<HealthSessionDetail>> fetchSessionsForDay(
    HealthMetricType metric,
    DateTime day, {
    HealthWorkoutType? workoutFilter,
  }) async {
    if (!_sessionMetrics.contains(metric) || !isMetricSupported(metric)) {
      return const [];
    }

    try {
      await _ensureConfigured();
      final points = await _fetchPoints(metric, day, workoutFilter);

      return points.map((point) {
        final value = point.value;
        final workoutType =
            metric == HealthMetricType.workouts && value is WorkoutHealthValue
                ? _mapWorkoutActivityType(value.workoutActivityType)
                : null;
        return HealthSessionDetail(
          start: point.dateFrom,
          end: point.dateTo,
          workoutType: workoutType,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  int _bedtimeMinutesOfDay(DateTime dateTime) {
    final minutes = dateTime.hour * 60 + dateTime.minute;
    return minutes < 12 * 60 ? minutes + 24 * 60 : minutes;
  }

  ({DateTime start, DateTime end}) _windowFor(
    HealthMetricType metric,
    DateTime day,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day);
    if (metric == HealthMetricType.sleep ||
        metric == HealthMetricType.bedtime ||
        metric == HealthMetricType.wakeTime) {
      // A night's sleep is attributed to the day the person wakes up on —
      // query from the previous noon through this noon rather than
      // midnight-to-midnight.
      final end = dayStart.add(const Duration(hours: 12));
      final start = end.subtract(const Duration(hours: 24));
      return (start: start, end: end);
    }
    return (start: dayStart, end: dayStart.add(const Duration(days: 1)));
  }
}
