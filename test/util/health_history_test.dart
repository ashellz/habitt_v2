import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/util/health_history.dart';

import '../fixtures/habit_factory.dart';

void main() {
  final today = DateTime(2026, 10, 21, 15, 30);

  Habit? Function(DateTime) snapshots(Map<DateTime, Habit> byDay) =>
      (day) => byDay[DateTime(day.year, day.month, day.day)];

  group('healthSyncDay', () {
    test('lands on today for every metric by default', () {
      for (final metric in HealthMetricType.values) {
        expect(healthSyncDay(metric, today), DateTime(2026, 10, 21));
      }
    });

    test('puts a day-before bedtime on yesterday and nothing else', () {
      expect(
        healthSyncDay(HealthMetricType.bedtime, today, bedtimeDayBefore: true),
        DateTime(2026, 10, 20),
      );
      expect(
        healthSyncDay(HealthMetricType.sleep, today, bedtimeDayBefore: true),
        DateTime(2026, 10, 21),
      );
    });
  });

  group('buildHealthHistory', () {
    test('returns seven days oldest first, ending today', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.steps,
        amount: 8000,
      );

      final history = buildHealthHistory(
        habit,
        snapshots({}),
        today: today,
      );

      expect(history.points, hasLength(7));
      expect(history.points.first.day, DateTime(2026, 10, 15));
      expect(history.points.last.day, DateTime(2026, 10, 21));
      expect(history.kind, HealthHistoryKind.amount);
      expect(history.target, 8000);
      expect(history.hasData, isFalse);
    });

    test('reads progress and completion from each day snapshot', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.steps,
        amount: 8000,
      );
      final history = buildHealthHistory(
        habit,
        snapshots({
          DateTime(2026, 10, 20): buildTestHabit(
            healthMetric: HealthMetricType.steps,
            amount: 8000,
            amountCompleted: 9000,
          )..completed = true,
          DateTime(2026, 10, 21): buildTestHabit(
            healthMetric: HealthMetricType.steps,
            amount: 8000,
            amountCompleted: 3000,
          ),
        }),
        today: today,
      );

      final yesterday = history.points[5];
      expect(yesterday.value, 9000);
      expect(yesterday.completed, isTrue);
      final now = history.points[6];
      expect(now.value, 3000);
      expect(now.completed, isFalse);
      expect(history.points[4].value, isNull);
      expect(history.hasData, isTrue);
    });

    test('sleep is read in minutes', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.sleep,
        amount: 480,
      );

      expect(
        buildHealthHistory(habit, snapshots({}), today: today).kind,
        HealthHistoryKind.sleepMinutes,
      );
    });

    test('duration habits read seconds and the duration target', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.workouts,
        trackingType: HabitTrackingType.duration,
        duration: 1800,
      );
      final history = buildHealthHistory(
        habit,
        snapshots({
          DateTime(2026, 10, 21): buildTestHabit(
            healthMetric: HealthMetricType.workouts,
            trackingType: HabitTrackingType.duration,
            duration: 1800,
            durationCompleted: 2400,
          ),
        }),
        today: today,
      );

      expect(history.kind, HealthHistoryKind.duration);
      expect(history.target, 1800);
      expect(history.points.last.value, 2400);
    });

    test('time-of-day habits skip reset days and carry the tolerance', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.wakeTime,
        trackingType: HabitTrackingType.timeOfDay,
        amount: 420,
        toleranceMinutes: 30,
      );
      final history = buildHealthHistory(
        habit,
        snapshots({
          DateTime(2026, 10, 20): buildTestHabit(
            healthMetric: HealthMetricType.wakeTime,
            trackingType: HabitTrackingType.timeOfDay,
            amountCompleted: 0,
          ),
          DateTime(2026, 10, 21): buildTestHabit(
            healthMetric: HealthMetricType.wakeTime,
            trackingType: HabitTrackingType.timeOfDay,
            amountCompleted: 435,
          ),
        }),
        today: today,
      );

      expect(history.kind, HealthHistoryKind.timeOfDay);
      expect(history.tolerance, 30);
      expect(history.points[5].value, isNull);
      expect(history.points[6].value, 435);
    });

    test('a day-before bedtime ends on yesterday', () {
      final habit = buildTestHabit(
        healthMetric: HealthMetricType.bedtime,
        trackingType: HabitTrackingType.timeOfDay,
        amount: 1380,
        healthBedtimeDayBefore: true,
      );

      final history = buildHealthHistory(
        habit,
        snapshots({}),
        today: today,
      );

      expect(history.points.last.day, DateTime(2026, 10, 20));
      expect(history.points.first.day, DateTime(2026, 10, 14));
    });
  });
}
