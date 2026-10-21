import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';

import '../fixtures/habit_factory.dart';

void main() {
  group('Habit.supportsTimer', () {
    test('is true for a plain duration habit', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.duration,
        duration: 600,
      );

      expect(habit.supportsTimer, isTrue);
    });

    test('is false for a Health-synced duration habit', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.duration,
        duration: 600,
        healthMetric: HealthMetricType.workouts,
      );

      expect(habit.supportsTimer, isFalse);
    });

    test('is false for bedtime and wake time habits', () {
      for (final metric in [
        HealthMetricType.bedtime,
        HealthMetricType.wakeTime,
      ]) {
        final habit = buildTestHabit(
          trackingType: HabitTrackingType.timeOfDay,
          healthMetric: metric,
          amount: 22 * 60,
        );

        expect(habit.supportsTimer, isFalse);
      }
    });

    test('is false for amount habits', () {
      expect(buildTestHabit().supportsTimer, isFalse);
    });
  });
}
