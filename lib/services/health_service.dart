import 'dart:io';

import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/util/health_history.dart';
import 'package:habitt/util/sleep_sessions.dart';
import 'package:habitt/util/workout_sessions.dart';
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
/// (1500) still sorts later than an 11:00 PM one (1380). Wake times don't
/// need this — they're always compared as plain minutes-since-midnight.
///
/// Sleep, bedtime and wake time are read as whole sleep sessions (see
/// `sleep_sessions.dart`) rather than a fixed clock window, so a night that
/// ends at 13:00 — or a night shift's 07:00–17:00 sleep — lands on the right
/// day.
class HealthService {
  HealthService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  // Every asleep sample, staged or not. Apple Watch (iOS 16+) and most
  // Health Connect trackers only write the stages, never plain "asleep".
  // Awake / in-bed samples are left out so they don't count as sleep.
  static const List<HealthDataType> _iosSleepTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  // Plus the session record itself, for sources that log a night without
  // stages — see [SleepSegment.isWholeSession].
  static const List<HealthDataType> _androidSleepTypes = [
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];

  // Health Connect has no mindfulness record type. bedtime/wakeTime reuse
  // the same sleep types as `sleep` — same read, different aggregation.
  static const Map<HealthMetricType, List<HealthDataType>> _iosTypes = {
    HealthMetricType.steps: [HealthDataType.STEPS],
    HealthMetricType.sleep: _iosSleepTypes,
    HealthMetricType.bedtime: _iosSleepTypes,
    HealthMetricType.wakeTime: _iosSleepTypes,
    HealthMetricType.workouts: [HealthDataType.WORKOUT],
    HealthMetricType.mindfulness: [HealthDataType.MINDFULNESS],
    HealthMetricType.activeCalories: [HealthDataType.ACTIVE_ENERGY_BURNED],
    HealthMetricType.totalCalories: [HealthDataType.TOTAL_CALORIES_BURNED],
  };

  static const Map<HealthMetricType, List<HealthDataType>> _androidTypes = {
    HealthMetricType.steps: [HealthDataType.STEPS],
    HealthMetricType.sleep: _androidSleepTypes,
    HealthMetricType.bedtime: _androidSleepTypes,
    HealthMetricType.wakeTime: _androidSleepTypes,
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

  Future<List<HealthDataPoint>> _fetchPoints(
    HealthMetricType metric,
    DateTime day,
  ) async {
    final window = _windowFor(day);
    final types = _typesByMetric[metric] ?? const [];
    if (types.isEmpty) return const [];

    return _health.getHealthDataFromTypes(
      types: types,
      startTime: window.start,
      endTime: window.end,
    );
  }

  /// The workouts recorded on [day], narrowed to [workoutFilter] when set.
  /// Both platforms read `WORKOUT` records, which carry an activity type and
  /// are one record per workout. Records of the same workout written by more
  /// than one source are folded into one — see [dedupOverlappingSessions].
  Future<List<HealthSessionDetail>> _fetchWorkoutSessions(
    DateTime day,
    HealthWorkoutType? workoutFilter,
  ) async {
    final points = await _fetchPoints(HealthMetricType.workouts, day);

    final sessions = <HealthSessionDetail>[];
    for (final point in points) {
      final value = point.value;
      if (value is! WorkoutHealthValue) continue;
      final type = _mapWorkoutActivityType(value.workoutActivityType);
      if (workoutFilter != null && type != workoutFilter) continue;
      sessions.add(
        HealthSessionDetail(
          start: point.dateFrom,
          end: point.dateTo,
          workoutType: type,
        ),
      );
    }
    return dedupOverlappingSessions(sessions);
  }

  // Sleep, bedtime and wake time all come from the same sleep samples,
  // grouped into sessions rather than cut by a clock window.
  static const Set<HealthMetricType> _sleepMetrics = {
    HealthMetricType.sleep,
    HealthMetricType.bedtime,
    HealthMetricType.wakeTime,
  };

  /// The sleep sessions that belong to [day] for [metric]: those the person
  /// woke up on [day]. A bedtime with [bedtimeDayBefore] instead takes the
  /// sessions the person woke up from on the day after [day]. Reads a day
  /// either side so a session that crosses midnight is never cut off, then
  /// keeps only the matching ones.
  Future<List<SleepSession>> _fetchSleepSessions(
    HealthMetricType metric,
    DateTime day, {
    bool bedtimeDayBefore = false,
  }) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final points = await _health.getHealthDataFromTypes(
      types: _typesByMetric[metric] ?? const [],
      startTime: DateTime(dayStart.year, dayStart.month, dayStart.day - 1),
      endTime: DateTime(dayStart.year, dayStart.month, dayStart.day + 2),
    );

    final segments = points.map(
      (point) => SleepSegment(
        start: point.dateFrom,
        end: point.dateTo,
        isWholeSession: point.type == HealthDataType.SLEEP_SESSION,
      ),
    );

    final countOnDayBefore =
        metric == HealthMetricType.bedtime && bedtimeDayBefore;
    return groupSleepSessions(segments).where((session) {
      final sessionDay =
          countOnDayBefore ? session.dayBeforeWake : session.wakeDay;
      return sessionDay == dayStart;
    }).toList();
  }

  /// The value for [metric] on the calendar [day], in the habit's native
  /// unit — a raw count for [HealthMetricType.steps]/calories, minutes for
  /// [HealthMetricType.sleep], seconds for duration-tracked metrics,
  /// minutes-since-midnight for [bedtime]/[wakeTime]. Returns `null` if the metric isn't supported on this
  /// platform or the read fails.
  ///
  /// [trackingType] only matters for [HealthMetricType.workouts] and
  /// [HealthMetricType.mindfulness]: a habit tracking `amount` gets the
  /// session *count* for the day instead of summed duration — same
  /// underlying read, different aggregation. [workoutFilter] narrows
  /// workout reads to one [HealthWorkoutType]. [bedtimeDayBefore] only
  /// matters for [HealthMetricType.bedtime] — see [_fetchSleepSessions].
  Future<int?> fetchValueForDay(
    HealthMetricType metric,
    DateTime day, {
    HabitTrackingType? trackingType,
    HealthWorkoutType? workoutFilter,
    bool bedtimeDayBefore = false,
  }) async {
    if (!isMetricSupported(metric)) return null;

    try {
      await _ensureConfigured();

      if (metric == HealthMetricType.steps) {
        final start = DateTime(day.year, day.month, day.day);
        final end = start.add(const Duration(days: 1));
        return _health.getTotalStepsInInterval(start, end);
      }

      if (_sleepMetrics.contains(metric)) {
        final sessions = await _fetchSleepSessions(
          metric,
          day,
          bedtimeDayBefore: bedtimeDayBefore,
        );
        switch (metric) {
          case HealthMetricType.bedtime:
            final main = mainSleepSession(sessions);
            return main == null ? null : _bedtimeMinutesOfDay(main.start);
          case HealthMetricType.wakeTime:
            final main = mainSleepSession(sessions);
            return main == null ? null : main.end.hour * 60 + main.end.minute;
          default:
            // Sleep is an amount habit whose target and tolerance are in
            // minutes, not a seconds-based duration habit.
            final totalMinutes = sessions.fold<double>(
              0,
              (sum, session) => sum + session.minutes,
            );
            return totalMinutes.round();
        }
      }

      if (metric == HealthMetricType.workouts) {
        final sessions = await _fetchWorkoutSessions(day, workoutFilter);
        if (trackingType == HabitTrackingType.amount) return sessions.length;
        // Workout records carry no duration value — it's the time each
        // session covers.
        return sessions.fold<int>(
          0,
          (sum, session) => sum + session.duration.inSeconds,
        );
      }

      final points = await _fetchPoints(metric, day);

      if (_countMetrics.contains(metric)) {
        final total = points.fold<double>(0, (sum, point) {
          final value = point.value;
          return value is NumericHealthValue
              ? sum + value.numericValue.toDouble()
              : sum;
        });
        return total.round();
      }

      if (_dualModeMetrics.contains(metric) &&
          trackingType == HabitTrackingType.amount) {
        return points.length;
      }

      // Mindfulness samples are declared in MINUTE units by the plugin, so
      // their numeric value is already a duration.
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
    bool bedtimeDayBefore = false,
  }) async {
    if (!_sessionMetrics.contains(metric) || !isMetricSupported(metric)) {
      return const [];
    }

    try {
      await _ensureConfigured();

      if (_sleepMetrics.contains(metric)) {
        final sessions = await _fetchSleepSessions(
          metric,
          day,
          bedtimeDayBefore: bedtimeDayBefore,
        );
        return sessions
            .map((s) => HealthSessionDetail(start: s.start, end: s.end))
            .toList();
      }

      if (metric == HealthMetricType.workouts) {
        return _fetchWorkoutSessions(day, workoutFilter);
      }

      final points = await _fetchPoints(metric, day);

      return points
          .map(
            (point) =>
                HealthSessionDetail(start: point.dateFrom, end: point.dateTo),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // returns day in database where the sync data should be written to
  // could be the day before in case user toggles that on for bedtime habit
  DateTime syncDayFor(
    HealthMetricType metric,
    DateTime today, {
    bool bedtimeDayBefore = false,
  }) {
    return healthSyncDay(metric, today, bedtimeDayBefore: bedtimeDayBefore);
  }

  int _bedtimeMinutesOfDay(DateTime dateTime) {
    final minutes = dateTime.hour * 60 + dateTime.minute;
    return minutes < 12 * 60 ? minutes + 24 * 60 : minutes;
  }

  ({DateTime start, DateTime end}) _windowFor(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    return (start: dayStart, end: dayStart.add(const Duration(days: 1)));
  }
}
