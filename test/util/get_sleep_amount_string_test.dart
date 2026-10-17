import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/util/get_sleep_amount_string.dart';

import '../fixtures/habit_factory.dart';

void main() {
  group('getSleepAmountString', () {
    test('shows the target as a duration before any sleep is synced', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        amount: 8 * 60,
      );

      expect(getSleepAmountString(habit), '8h');
    });

    test('shows progress / target while under the target', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        amount: 8 * 60,
      )..updateHabitAmountCompleted(6 * 60 + 15);

      expect(getSleepAmountString(habit), '6h15m / 8h');
    });

    test('shows only the slept duration once completed', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        amount: 8 * 60,
        toleranceMinutes: 30,
      )..updateHabitAmountCompleted(7 * 60 + 40);

      expect(habit.completed, isTrue);
      expect(getSleepAmountString(habit), '7h40m');
    });
  });
}
