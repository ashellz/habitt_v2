import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';

import '../fixtures/habit_factory.dart';

void main() {
  group('HealthMetricType.trackingType', () {
    test('steps and calorie metrics map to amount tracking', () {
      expect(
        HealthMetricType.steps.trackingType,
        HabitTrackingType.amount,
      );
      expect(
        HealthMetricType.activeCalories.trackingType,
        HabitTrackingType.amount,
      );
      expect(
        HealthMetricType.totalCalories.trackingType,
        HabitTrackingType.amount,
      );
    });

    test('sleep, exercise and mindfulness map to duration tracking', () {
      expect(
        HealthMetricType.sleep.trackingType,
        HabitTrackingType.duration,
      );
      expect(
        HealthMetricType.exerciseMinutes.trackingType,
        HabitTrackingType.duration,
      );
      expect(
        HealthMetricType.mindfulMinutes.trackingType,
        HabitTrackingType.duration,
      );
    });
  });

  group('Habit.healthMetric persistence', () {
    test('toMap/fromMap round-trips the linked metric', () {
      final habit = buildTestHabit(healthMetric: HealthMetricType.steps);

      final restored = Habit.fromMap(habit.toMap());

      expect(restored.healthMetric, HealthMetricType.steps);
    });

    test('toMap/fromMap round-trips an unlinked habit as null', () {
      final habit = buildTestHabit();

      final restored = Habit.fromMap(habit.toMap());

      expect(restored.healthMetric, isNull);
    });

    test('copy() preserves the linked metric', () {
      final habit = buildTestHabit(healthMetric: HealthMetricType.sleep);

      expect(habit.copy().healthMetric, HealthMetricType.sleep);
    });

    test('updateHabit() adopts the incoming metric and stamps a timestamp', () {
      final habit = buildTestHabit();
      final edited = buildTestHabit(healthMetric: HealthMetricType.mindfulMinutes);

      habit.updateHabit(edited);

      expect(habit.healthMetric, HealthMetricType.mindfulMinutes);
      expect(habit.timestamps['healthMetric'], isNotNull);
    });
  });

  group('Habit.merge healthMetric resolution', () {
    test('the more recently stamped side wins', () {
      final now = DateTime.now().toUtc();
      final local = buildTestHabit(
        healthMetric: HealthMetricType.steps,
        timestamps: {'healthMetric': now.subtract(const Duration(days: 1))},
      );
      final incoming = buildTestHabit(
        healthMetric: HealthMetricType.exerciseMinutes,
        timestamps: {'healthMetric': now},
      );

      final merged = local.merge(incoming, reference: now);

      expect(merged.healthMetric, HealthMetricType.exerciseMinutes);
    });

    test('ties prefer the local value', () {
      final now = DateTime.now().toUtc();
      final local = buildTestHabit(
        healthMetric: HealthMetricType.steps,
        timestamps: {'healthMetric': now},
      );
      final incoming = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        timestamps: {'healthMetric': now},
      );

      final merged = local.merge(incoming, reference: now);

      expect(merged.healthMetric, HealthMetricType.steps);
    });
  });
}
