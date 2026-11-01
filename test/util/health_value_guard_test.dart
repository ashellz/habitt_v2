import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/util/health_value_guard.dart';

void main() {
  group('isPlausibleHealthValue', () {
    test('negative values are never plausible', () {
      for (final metric in HealthMetricType.values) {
        expect(isPlausibleHealthValue(metric, -1), isFalse, reason: '$metric');
      }
    });

    test('steps', () {
      expect(isPlausibleHealthValue(HealthMetricType.steps, 0), isTrue);
      expect(isPlausibleHealthValue(HealthMetricType.steps, 42000), isTrue);
      expect(isPlausibleHealthValue(HealthMetricType.steps, 400000), isFalse);
    });

    test('calories', () {
      expect(isPlausibleHealthValue(HealthMetricType.totalCalories, 3500), isTrue);
      expect(
        isPlausibleHealthValue(HealthMetricType.activeCalories, 900000),
        isFalse,
      );
    });

    test('sleep is minutes and tops out at a day', () {
      expect(isPlausibleHealthValue(HealthMetricType.sleep, 8 * 60), isTrue);
      expect(isPlausibleHealthValue(HealthMetricType.sleep, 24 * 60), isTrue);
      expect(isPlausibleHealthValue(HealthMetricType.sleep, 30 * 60), isFalse);
    });

    test('workouts: session count in Amount mode, seconds in Duration mode', () {
      expect(
        isPlausibleHealthValue(
          HealthMetricType.workouts,
          3,
          trackingType: HabitTrackingType.amount,
        ),
        isTrue,
      );
      expect(
        isPlausibleHealthValue(
          HealthMetricType.workouts,
          5000,
          trackingType: HabitTrackingType.amount,
        ),
        isFalse,
      );
      expect(
        isPlausibleHealthValue(
          HealthMetricType.workouts,
          5000,
          trackingType: HabitTrackingType.duration,
        ),
        isTrue,
      );
      expect(
        isPlausibleHealthValue(
          HealthMetricType.mindfulness,
          100000,
          trackingType: HabitTrackingType.duration,
        ),
        isFalse,
      );
    });

    test('activity is seconds and tops out at a day', () {
      expect(isPlausibleHealthValue(HealthMetricType.activity, 1800), isTrue);
      expect(isPlausibleHealthValue(HealthMetricType.activity, 90000), isFalse);
    });

    test('bedtime keeps the before-noon +24h convention', () {
      expect(isPlausibleHealthValue(HealthMetricType.bedtime, 22 * 60), isTrue);
      // 01:00 is stored as 25h
      expect(isPlausibleHealthValue(HealthMetricType.bedtime, 25 * 60), isTrue);
      expect(isPlausibleHealthValue(HealthMetricType.bedtime, 40 * 60), isFalse);
    });

    test('wake time is a plain time of day', () {
      expect(isPlausibleHealthValue(HealthMetricType.wakeTime, 7 * 60), isTrue);
      expect(isPlausibleHealthValue(HealthMetricType.wakeTime, 25 * 60), isFalse);
    });
  });

  group('shouldDiscardHealthValue', () {
    test('empty read over existing progress is discarded', () {
      expect(shouldDiscardHealthValue(HealthMetricType.steps, 0, 5000), isTrue);
    });

    test('empty read on an empty day is a normal write', () {
      expect(shouldDiscardHealthValue(HealthMetricType.steps, 0, 0), isFalse);
    });

    test('a lower but real value is followed, not discarded', () {
      expect(
        shouldDiscardHealthValue(HealthMetricType.steps, 1200, 5000),
        isFalse,
      );
    });

    test('a higher value is followed', () {
      expect(
        shouldDiscardHealthValue(HealthMetricType.steps, 9000, 5000),
        isFalse,
      );
    });

    test('a corrupt value is discarded even on an empty day', () {
      expect(
        shouldDiscardHealthValue(HealthMetricType.steps, 999999, 0),
        isTrue,
      );
      expect(shouldDiscardHealthValue(HealthMetricType.sleep, -5, 0), isTrue);
    });
  });

  group('sameHealthSessions', () {
    HealthSessionDetail session(int h, {HealthWorkoutType? type}) =>
        HealthSessionDetail(
          start: DateTime(2026, 1, 1, h),
          end: DateTime(2026, 1, 1, h + 1),
          workoutType: type,
        );

    test('two empty lists match', () {
      expect(sameHealthSessions(const [], const []), isTrue);
    });

    test('equal sessions match', () {
      expect(sameHealthSessions([session(8)], [session(8)]), isTrue);
    });

    test('the same moment in local and UTC matches', () {
      final local = HealthSessionDetail(
        start: DateTime(2026, 1, 1, 8),
        end: DateTime(2026, 1, 1, 9),
      );
      final utc = HealthSessionDetail(
        start: DateTime(2026, 1, 1, 8).toUtc(),
        end: DateTime(2026, 1, 1, 9).toUtc(),
      );
      expect(sameHealthSessions([local], [utc]), isTrue);
    });

    test('a different count, time or workout type does not match', () {
      expect(sameHealthSessions([session(8)], const []), isFalse);
      expect(sameHealthSessions([session(8)], [session(9)]), isFalse);
      expect(
        sameHealthSessions(
          [session(8, type: HealthWorkoutType.running)],
          [session(8, type: HealthWorkoutType.walking)],
        ),
        isFalse,
      );
    });
  });
}
