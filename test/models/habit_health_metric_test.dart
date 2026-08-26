import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/models/health_workout_type.dart';

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

    test('sleep maps to amount tracking (so tolerance can apply)', () {
      expect(HealthMetricType.sleep.trackingType, HabitTrackingType.amount);
    });

    test('workouts and mindfulness default to duration tracking', () {
      expect(
        HealthMetricType.workouts.trackingType,
        HabitTrackingType.duration,
      );
      expect(
        HealthMetricType.mindfulness.trackingType,
        HabitTrackingType.duration,
      );
    });

    test('bedtime and wakeTime map to timeOfDay tracking', () {
      expect(
        HealthMetricType.bedtime.trackingType,
        HabitTrackingType.timeOfDay,
      );
      expect(
        HealthMetricType.wakeTime.trackingType,
        HabitTrackingType.timeOfDay,
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
      final edited = buildTestHabit(healthMetric: HealthMetricType.mindfulness);

      habit.updateHabit(edited);

      expect(habit.healthMetric, HealthMetricType.mindfulness);
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
        healthMetric: HealthMetricType.workouts,
        timestamps: {'healthMetric': now},
      );

      final merged = local.merge(incoming, reference: now);

      expect(merged.healthMetric, HealthMetricType.workouts);
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

  group('Habit.healthWorkoutFilter persistence', () {
    test('toMap/fromMap round-trips the workout filter', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.workouts,
        healthWorkoutFilter: HealthWorkoutType.running,
      );

      final restored = Habit.fromMap(habit.toMap());

      expect(restored.healthWorkoutFilter, HealthWorkoutType.running);
    });

    test('null workout filter round-trips as null (combined workout)', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.workouts,
      );

      final restored = Habit.fromMap(habit.toMap());

      expect(restored.healthWorkoutFilter, isNull);
    });
  });

  group('Habit.healthSessions day-state', () {
    test('toMap/fromMap round-trips sessions', () {
      final start = DateTime.utc(2026, 1, 1, 7);
      final end = DateTime.utc(2026, 1, 1, 7, 32);
      final habit = buildTestHabit(
        healthSessions: [
          HealthSessionDetail(
            start: start,
            end: end,
            workoutType: HealthWorkoutType.running,
          ),
        ],
      );

      final restored = Habit.fromMap(habit.toMap());

      expect(restored.healthSessions, hasLength(1));
      expect(restored.healthSessions.first.start, start);
      expect(restored.healthSessions.first.end, end);
      expect(
        restored.healthSessions.first.workoutType,
        HealthWorkoutType.running,
      );
    });

    test('adoptDayState copies sessions from the day snapshot', () {
      final habit = buildTestHabit();
      final snapshot = buildTestHabit(
        healthSessions: [
          HealthSessionDetail(
            start: DateTime.utc(2026, 1, 1, 7),
            end: DateTime.utc(2026, 1, 1, 7, 30),
          ),
        ],
      );

      habit.adoptDayState(snapshot);

      expect(habit.healthSessions, hasLength(1));
    });

    test('clearDayState empties sessions', () {
      final habit = buildTestHabit(
        healthSessions: [
          HealthSessionDetail(
            start: DateTime.utc(2026, 1, 1, 7),
            end: DateTime.utc(2026, 1, 1, 7, 30),
          ),
        ],
      );

      habit.clearDayState();

      expect(habit.healthSessions, isEmpty);
    });

    test('merge picks sessions from the same side as the completion tuple', () {
      final now = DateTime.now().toUtc();
      final local = buildTestHabit(
        amountCompleted: 5,
        healthSessions: [
          HealthSessionDetail(
            start: DateTime.utc(2026, 1, 1, 7),
            end: DateTime.utc(2026, 1, 1, 7, 30),
          ),
        ],
        timestamps: {'amountCompleted': now},
      );
      final incoming = buildTestHabit(
        amountCompleted: 8,
        healthSessions: [
          HealthSessionDetail(
            start: DateTime.utc(2026, 1, 1, 6),
            end: DateTime.utc(2026, 1, 1, 6, 45),
          ),
          HealthSessionDetail(
            start: DateTime.utc(2026, 1, 1, 18),
            end: DateTime.utc(2026, 1, 1, 18, 20),
          ),
        ],
        timestamps: {'amountCompleted': now.subtract(const Duration(hours: 1))},
      );

      final merged = local.merge(incoming, reference: now);

      // Local's amountCompleted timestamp is more recent, so the whole
      // completion tuple (including sessions) should come from local.
      expect(merged.amountCompleted, 5);
      expect(merged.healthSessions, hasLength(1));
    });
  });

  group('Habit trackingType inference (_inferTrackingType)', () {
    test(
      'a bedtime-linked habit with no explicit trackingType still infers '
      'timeOfDay, not amount, even though amount holds a large minute value',
      () {
        // Simulates legacy/corrupted data: trackingType missing from the
        // map, but healthMetric present. Without checking healthMetric
        // first, amount=1320 (10:00 PM) would satisfy `amount >= 1` and
        // silently misclassify as an amount goal instead.
        final map = buildTestHabit(
          healthMetric: HealthMetricType.bedtime,
          amount: 22 * 60,
        ).toMap();
        map.remove('trackingType');

        final restored = Habit.fromMap(map);

        expect(restored.trackingType, HabitTrackingType.timeOfDay);
      },
    );

    test('a wakeTime-linked habit infers timeOfDay the same way', () {
      final map = buildTestHabit(
        healthMetric: HealthMetricType.wakeTime,
        amount: 7 * 60,
      ).toMap();
      map.remove('trackingType');

      final restored = Habit.fromMap(map);

      expect(restored.trackingType, HabitTrackingType.timeOfDay);
    });

    test('a plain amount habit still infers amount as before', () {
      final map = buildTestHabit(amount: 10).toMap();
      map.remove('trackingType');

      final restored = Habit.fromMap(map);

      expect(restored.trackingType, HabitTrackingType.amount);
    });
  });

  group('Habit.updateHabitTimeOfDayCompleted', () {
    test('earlier than target completes regardless of tolerance', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.timeOfDay,
        amount: 22 * 60, // 10:00 PM target
        toleranceMinutes: 15,
      );

      habit.updateHabitTimeOfDayCompleted(21 * 60 + 50); // 9:50 PM

      expect(habit.completed, isTrue);
      expect(habit.amountCompleted, 21 * 60 + 50);
    });

    test('within tolerance still completes', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.timeOfDay,
        amount: 22 * 60,
        toleranceMinutes: 30,
      );

      habit.updateHabitTimeOfDayCompleted(22 * 60 + 25); // 10:25 PM

      expect(habit.completed, isTrue);
    });

    test('past tolerance does not complete', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.timeOfDay,
        amount: 22 * 60,
        toleranceMinutes: 30,
      );

      habit.updateHabitTimeOfDayCompleted(22 * 60 + 35); // 10:35 PM

      expect(habit.completed, isFalse);
    });

    test('a tighter tolerance can un-complete a previously-met target', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.timeOfDay,
        amount: 22 * 60,
        toleranceMinutes: 60,
      );
      habit.updateHabitTimeOfDayCompleted(22 * 60 + 45);
      expect(habit.completed, isTrue);

      habit.toleranceMinutes = 15;
      habit.updateHabitTimeOfDayCompleted(22 * 60 + 45);

      expect(habit.completed, isFalse);
    });
  });

  group('Habit.updateHabitAmountCompleted tolerance', () {
    test('zero tolerance (the default) is bit-for-bit today\'s behavior', () {
      final habit = buildTestHabit(amount: 10, toleranceMinutes: 0);

      habit.updateHabitAmountCompleted(9);
      expect(habit.completed, isFalse);

      habit.updateHabitAmountCompleted(10);
      expect(habit.completed, isTrue);
    });

    test('new Habit()/premade defaults leave toleranceMinutes at 0', () {
      // Regression guard for the bug this change's task 2.2 caught: the
      // constructor used to default toleranceMinutes to 30, which every
      // amount habit (not just sleep) would silently inherit.
      final habit = buildTestHabit();
      expect(habit.toleranceMinutes, 0);
    });

    test('sleep habit completes within tolerance (7h vs 8h target, 1h tolerance)', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        amount: 8 * 60,
        toleranceMinutes: 60,
      );

      habit.updateHabitAmountCompleted(7 * 60);

      expect(habit.completed, isTrue);
    });

    test('sleep habit fails outside tolerance (6h49m vs 8h target, 1h tolerance)', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        amount: 8 * 60,
        toleranceMinutes: 60,
      );

      habit.updateHabitAmountCompleted(6 * 60 + 49);

      expect(habit.completed, isFalse);
    });

    test('sleeping past the target always completes regardless of tolerance', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        amount: 8 * 60,
        toleranceMinutes: 60,
      );

      habit.updateHabitAmountCompleted(9 * 60);

      expect(habit.completed, isTrue);
    });
  });
}
