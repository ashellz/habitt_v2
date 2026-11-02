import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/services/health_service.dart';
import 'package:health/health.dart';

/// Stands in for the `health` plugin: answers from [points] and counts how
/// many times Health was asked.
class _FakeHealth extends Health {
  _FakeHealth(this.points, {this.steps});

  final List<HealthDataPoint> points;
  final int? steps;
  int pointReads = 0;
  int stepReads = 0;

  @override
  Future<void> configure() async {}

  @override
  Future<List<HealthDataPoint>> getHealthDataFromTypes({
    required List<HealthDataType> types,
    Map<HealthDataType, HealthDataUnit>? preferredUnits,
    required DateTime startTime,
    required DateTime endTime,
    List<RecordingMethod> recordingMethodsToFilter = const [],
  }) async {
    pointReads++;
    return points;
  }

  @override
  Future<int?> getTotalStepsInInterval(
    DateTime startTime,
    DateTime endTime, {
    bool includeManualEntry = true,
  }) async {
    stepReads++;
    return steps;
  }
}

HealthDataPoint _workout(
  HealthWorkoutActivityType type,
  DateTime from,
  DateTime to,
) => HealthDataPoint(
  uuid: 'workout-${from.microsecondsSinceEpoch}',
  value: WorkoutHealthValue(workoutActivityType: type),
  type: HealthDataType.WORKOUT,
  unit: HealthDataUnit.NO_UNIT,
  dateFrom: from,
  dateTo: to,
  sourcePlatform: HealthPlatformType.appleHealth,
  sourceDeviceId: 'test',
  sourceId: 'test',
  sourceName: 'test',
);

HealthDataPoint _point(
  HealthDataType type,
  DateTime from,
  DateTime to, {
  num value = 0,
}) => HealthDataPoint(
  uuid: '${type.name}-${from.microsecondsSinceEpoch}',
  value: NumericHealthValue(numericValue: value),
  type: type,
  unit: HealthDataUnit.NO_UNIT,
  dateFrom: from,
  dateTo: to,
  sourcePlatform: HealthPlatformType.appleHealth,
  sourceDeviceId: 'test',
  sourceId: 'test',
  sourceName: 'test',
);

void main() {
  // the plugin is only configured through the fake, platform checks (iOS
  // metric table on the test host) still apply
  final day = DateTime(2026, 10, 30);

  group('HealthService.fetchDay reads Health once', () {
    test('sleep: value and sessions come from a single read', () async {
      final health = _FakeHealth([
        _point(
          HealthDataType.SLEEP_ASLEEP,
          DateTime(2026, 10, 29, 23),
          DateTime(2026, 10, 30, 7),
        ),
      ]);
      final reading = await HealthService(
        health: health,
      ).fetchDay(HealthMetricType.sleep, day);

      expect(health.pointReads, 1);
      expect(reading, isNotNull);
      expect(reading!.value, 8 * 60);
      expect(reading.sessions, hasLength(1));
      expect(reading.sessions.single.start, DateTime(2026, 10, 29, 23));
    });

    test('wake time: value is the end of the night, one read', () async {
      final health = _FakeHealth([
        _point(
          HealthDataType.SLEEP_ASLEEP,
          DateTime(2026, 10, 29, 23),
          DateTime(2026, 10, 30, 7, 30),
        ),
      ]);
      final reading = await HealthService(
        health: health,
      ).fetchDay(HealthMetricType.wakeTime, day);

      expect(health.pointReads, 1);
      expect(reading!.value, 7 * 60 + 30);
      expect(reading.sessions, hasLength(1));
    });

    test('bedtime with no sleep session has no reading', () async {
      final health = _FakeHealth(const []);
      final reading = await HealthService(
        health: health,
      ).fetchDay(HealthMetricType.bedtime, day);

      expect(reading, isNull);
      expect(health.pointReads, 1);
    });

    test('sleep with no data reads as 0 minutes and no sessions', () async {
      final health = _FakeHealth(const []);
      final reading = await HealthService(
        health: health,
      ).fetchDay(HealthMetricType.sleep, day);

      expect(reading!.value, 0);
      expect(reading.sessions, isEmpty);
    });

    test('activity: minutes covered and grouped periods, one read', () async {
      final health = _FakeHealth([
        _point(
          HealthDataType.EXERCISE_TIME,
          DateTime(2026, 10, 30, 10, 0),
          DateTime(2026, 10, 30, 10, 1),
        ),
        _point(
          HealthDataType.EXERCISE_TIME,
          DateTime(2026, 10, 30, 10, 1),
          DateTime(2026, 10, 30, 10, 2),
        ),
      ]);
      final reading = await HealthService(
        health: health,
      ).fetchDay(HealthMetricType.activity, day);

      expect(health.pointReads, 1);
      expect(reading!.value, 120);
      expect(reading.sessions, hasLength(1));
    });

    test('mindfulness: duration mode sums minutes, amount mode counts, both list sessions', () async {
      List<HealthDataPoint> points() => [
        _point(
          HealthDataType.MINDFULNESS,
          DateTime(2026, 10, 30, 8),
          DateTime(2026, 10, 30, 8, 10),
          value: 10,
        ),
        _point(
          HealthDataType.MINDFULNESS,
          DateTime(2026, 10, 30, 20),
          DateTime(2026, 10, 30, 20, 5),
          value: 5,
        ),
      ];

      final duration = _FakeHealth(points());
      final durationReading = await HealthService(health: duration).fetchDay(
        HealthMetricType.mindfulness,
        day,
        trackingType: HabitTrackingType.duration,
      );
      expect(duration.pointReads, 1);
      expect(durationReading!.value, 15 * 60);
      expect(durationReading.sessions, hasLength(2));

      final amount = _FakeHealth(points());
      final amountReading = await HealthService(health: amount).fetchDay(
        HealthMetricType.mindfulness,
        day,
        trackingType: HabitTrackingType.amount,
      );
      expect(amountReading!.value, 2);
      expect(amountReading.sessions, hasLength(2));
    });

    test('workouts: seconds in Duration mode, a count in Amount mode, one read each', () async {
      List<HealthDataPoint> points() => [
        _workout(
          HealthWorkoutActivityType.RUNNING,
          DateTime(2026, 10, 30, 7),
          DateTime(2026, 10, 30, 7, 30),
        ),
        _workout(
          HealthWorkoutActivityType.YOGA,
          DateTime(2026, 10, 30, 18),
          DateTime(2026, 10, 30, 18, 20),
        ),
      ];

      final duration = _FakeHealth(points());
      final durationReading = await HealthService(health: duration).fetchDay(
        HealthMetricType.workouts,
        day,
        trackingType: HabitTrackingType.duration,
      );
      expect(duration.pointReads, 1);
      expect(durationReading!.value, 50 * 60);
      expect(durationReading.sessions, hasLength(2));

      final amount = _FakeHealth(points());
      final amountReading = await HealthService(health: amount).fetchDay(
        HealthMetricType.workouts,
        day,
        trackingType: HabitTrackingType.amount,
      );
      expect(amount.pointReads, 1);
      expect(amountReading!.value, 2);
      expect(amountReading.sessions, hasLength(2));
    });

    test('calories: a summed count with no sessions', () async {
      final health = _FakeHealth([
        _point(
          HealthDataType.ACTIVE_ENERGY_BURNED,
          DateTime(2026, 10, 30, 8),
          DateTime(2026, 10, 30, 9),
          value: 200.4,
        ),
        _point(
          HealthDataType.ACTIVE_ENERGY_BURNED,
          DateTime(2026, 10, 30, 12),
          DateTime(2026, 10, 30, 13),
          value: 150,
        ),
      ]);
      final reading = await HealthService(
        health: health,
      ).fetchDay(HealthMetricType.activeCalories, day);

      expect(health.pointReads, 1);
      expect(reading!.value, 350);
      expect(reading.sessions, isEmpty);
    });

    test('steps: the interval total with no sessions', () async {
      final health = _FakeHealth(const [], steps: 7421);
      final reading = await HealthService(
        health: health,
      ).fetchDay(HealthMetricType.steps, day);

      expect(health.stepReads, 1);
      expect(health.pointReads, 0);
      expect(reading!.value, 7421);
      expect(reading.sessions, isEmpty);
    });

    test('steps: a null total is no reading', () async {
      final reading = await HealthService(
        health: _FakeHealth(const [], steps: null),
      ).fetchDay(HealthMetricType.steps, day);

      expect(reading, isNull);
    });
  });
}
