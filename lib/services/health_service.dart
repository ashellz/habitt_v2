import 'dart:io';

import 'package:habitt/models/health_metric_type.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class HealthService {
  HealthService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const Map<HealthMetricType, List<HealthDataType>> _iosTypes = {
    HealthMetricType.steps: [HealthDataType.STEPS],
    HealthMetricType.sleep: [HealthDataType.SLEEP_ASLEEP],
    HealthMetricType.exerciseMinutes: [HealthDataType.EXERCISE_TIME],
    HealthMetricType.mindfulMinutes: [HealthDataType.MINDFULNESS],
    HealthMetricType.activeCalories: [HealthDataType.ACTIVE_ENERGY_BURNED],
    HealthMetricType.totalCalories: [HealthDataType.TOTAL_CALORIES_BURNED],
  };

  static const Map<HealthMetricType, List<HealthDataType>> _androidTypes = {
    HealthMetricType.steps: [HealthDataType.STEPS],
    HealthMetricType.sleep: [HealthDataType.SLEEP_ASLEEP],
    HealthMetricType.exerciseMinutes: [HealthDataType.WORKOUT],
    HealthMetricType.activeCalories: [HealthDataType.ACTIVE_ENERGY_BURNED],
    HealthMetricType.totalCalories: [HealthDataType.TOTAL_CALORIES_BURNED],
  };

  // amount metrics, not duration metrics
  static const Set<HealthMetricType> _countMetrics = {
    HealthMetricType.steps,
    HealthMetricType.activeCalories,
    HealthMetricType.totalCalories,
  };

  Map<HealthMetricType, List<HealthDataType>> get _typesByMetric =>
      Platform.isAndroid ? _androidTypes : _iosTypes;

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

  Future<bool> requestAuthorization() async {
    await _ensureConfigured();

    if (Platform.isAndroid) {
      await ph.Permission.activityRecognition.request();
    }

    return _health.requestAuthorization(
      _allTypes,
      permissions: List.filled(_allTypes.length, HealthDataAccess.READ),
    );
  }

  Future<int?> fetchValueForDay(HealthMetricType metric, DateTime day) async {
    if (!isMetricSupported(metric)) return null;

    try {
      await _ensureConfigured();

      if (metric == HealthMetricType.steps) {
        final start = DateTime(day.year, day.month, day.day);
        final end = start.add(const Duration(days: 1));
        final steps = await _health.getTotalStepsInInterval(start, end);
        return steps;
      }

      final window = _windowFor(metric, day);
      final types = _typesByMetric[metric]!;
      final points = await _health.getHealthDataFromTypes(
        types: types,
        startTime: window.start,
        endTime: window.end,
      );

      if (_countMetrics.contains(metric)) {
        // for calories sum the numeric kilocalorie value of each point directly
        final total = points.fold<double>(0, (sum, point) {
          final value = point.value;
          return value is NumericHealthValue
              ? sum + value.numericValue.toDouble()
              : sum;
        });
        return total.round();
      }

      if (Platform.isAndroid && metric == HealthMetricType.exerciseMinutes) {
        // no duration values, summing from start to end
        final totalSeconds = points.fold<int>(
          0,
          (sum, point) =>
              sum + point.dateTo.difference(point.dateFrom).inSeconds,
        );
        return totalSeconds;
      }

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

  ({DateTime start, DateTime end}) _windowFor(
    HealthMetricType metric,
    DateTime day,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day);
    if (metric == HealthMetricType.sleep) {
      // a sleep session is assigned to the day the person wakes up on
      final end = dayStart.add(const Duration(hours: 12));
      final start = end.subtract(const Duration(hours: 24));
      return (start: start, end: end);
    }
    return (start: dayStart, end: dayStart.add(const Duration(days: 1)));
  }
}
