import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';

import '../fixtures/habit_factory.dart';

Habit _overridden() =>
    buildTestHabit(
        healthMetric: HealthMetricType.workouts,
        trackingType: HabitTrackingType.duration,
        amount: 0,
        duration: 1800,
      )
      ..healthManualOverride = true;

void main() {
  final now = DateTime.utc(2026, 6, 22, 9);

  group('Habit.healthManualOverride', () {
    test('defaults to false', () {
      expect(buildTestHabit().healthManualOverride, isFalse);
    });

    test('survives copy, toMap/fromMap and adoptDayState', () {
      final habit = _overridden();

      expect(habit.copy().healthManualOverride, isTrue);
      expect(
        Habit.fromMap(habit.toMap()).healthManualOverride,
        isTrue,
      );

      final fresh = buildTestHabit(
        healthMetric: HealthMetricType.workouts,
        trackingType: HabitTrackingType.duration,
        duration: 1800,
      )..adoptDayState(habit);
      expect(fresh.healthManualOverride, isTrue);
    });

    test('an old backup without the key reads as not overridden', () {
      final map = _overridden().toMap()..remove('healthManualOverride');
      expect(Habit.fromMap(map).healthManualOverride, isFalse);
    });

    test('a new day starts without the override', () {
      final habit = _overridden();

      expect(habit.copyResetCompletion().healthManualOverride, isFalse);

      habit.resetCompletion();
      expect(habit.healthManualOverride, isFalse);
    });

    test('clearDayState drops the override', () {
      final habit = _overridden()..clearDayState();
      expect(habit.healthManualOverride, isFalse);
    });

    test('merge keeps the override with the day-state that wins', () {
      final local =
          _overridden()
            ..durationCompleted = 3300
            ..timestamps['durationCompleted'] = DateTime.utc(2026, 6, 22, 8);
      final incoming =
          buildTestHabit(
              healthMetric: HealthMetricType.workouts,
              trackingType: HabitTrackingType.duration,
              duration: 1800,
              durationCompleted: 1200,
            )
            ..timestamps['durationCompleted'] = DateTime.utc(2026, 6, 21, 8);

      final merged = local.merge(incoming, reference: now);

      expect(merged.durationCompleted, 3300);
      expect(merged.healthManualOverride, isTrue);
    });
  });
}
