import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/premade_health_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/premade_template_factory.dart';

void main() {
  final steps = buildTestTemplate(
    healthMetric: HealthMetricType.steps,
    amount: 6000,
  );

  PremadeHealthDecision decide({
    bool hasMetric = true,
    bool available = true,
    bool supported = true,
    bool granted = false,
    bool accepted = false,
  }) => decidePremadeHealthPrompt(
    template: hasMetric ? steps : buildTestTemplate(amount: 1),
    isAvailable: available,
    isMetricSupported: supported,
    permissionGranted: granted,
    previouslyAccepted: accepted,
  );

  group('decidePremadeHealthPrompt', () {
    test('a template without a Health metric never asks', () {
      expect(decide(hasMetric: false), PremadeHealthDecision.notHealthLinked);
    });

    test('asks on a fresh device', () {
      expect(decide(), PremadeHealthDecision.ask);
    });

    test('skips and opens manual when Health is unavailable', () {
      expect(decide(available: false), PremadeHealthDecision.manualOnly);
      expect(
        decide(available: false, granted: true, accepted: true),
        PremadeHealthDecision.manualOnly,
      );
    });

    test('skips and opens manual when the platform lacks the metric', () {
      expect(decide(supported: false), PremadeHealthDecision.manualOnly);
    });

    test('skips the dialog when accepted before and access is granted', () {
      expect(
        decide(granted: true, accepted: true),
        PremadeHealthDecision.syncWithoutAsking,
      );
    });

    test('asks again if accepted before but access is no longer granted', () {
      expect(decide(accepted: true), PremadeHealthDecision.ask);
    });

    test('asks if access is granted but the dialog was never accepted', () {
      expect(decide(granted: true), PremadeHealthDecision.ask);
    });
  });

  group('accepted flag', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to false and sticks once saved', () async {
      expect(await loadPremadeHealthSyncAccepted(), isFalse);
      await savePremadeHealthSyncAccepted();
      expect(await loadPremadeHealthSyncAccepted(), isTrue);
    });
  });

  group('StateProvider.disablePremadeHealthSync', () {
    late StateProvider sp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sp = StateProvider(await SharedPreferences.getInstance());
    });

    test('clears metric, filter and tolerance on a steps habit', () {
      sp.applyPremadeHabitTemplate(steps);
      expect(sp.selectedHealthMetric, HealthMetricType.steps);

      sp.disablePremadeHealthSync(steps);

      expect(sp.selectedHealthMetric, isNull);
      expect(sp.selectedHealthWorkoutFilter, isNull);
      expect(sp.toleranceMinutes, 0);
      expect(sp.selectedHabitTrackingType, HabitTrackingType.amount);
      expect(sp.habitAmount, 6000);
    });

    test('a duration workout stays a duration habit without the filter', () {
      final run = buildTestTemplate(
        healthMetric: HealthMetricType.workouts,
        workoutFilter: HealthWorkoutType.running,
        durationMinutes: 30,
      );
      sp.applyPremadeHabitTemplate(run);
      expect(sp.selectedHealthWorkoutFilter, HealthWorkoutType.running);

      sp.disablePremadeHealthSync(run);

      expect(sp.selectedHealthMetric, isNull);
      expect(sp.selectedHealthWorkoutFilter, isNull);
      expect(sp.selectedHabitTrackingType, HabitTrackingType.duration);
      expect(sp.habitDuration, const Duration(minutes: 30));
    });

    test('sleep (minutes as amount) becomes a duration of the same length', () {
      final sleep = buildTestTemplate(
        healthMetric: HealthMetricType.sleep,
        amount: 8 * 60,
        toleranceMinutes: 30,
      );
      sp.applyPremadeHabitTemplate(sleep);
      expect(sp.selectedHabitTrackingType, HabitTrackingType.amount);

      sp.disablePremadeHealthSync(sleep);

      expect(sp.selectedHealthMetric, isNull);
      expect(sp.toleranceMinutes, 0);
      expect(sp.selectedHabitTrackingType, HabitTrackingType.duration);
      expect(sp.habitDuration, const Duration(hours: 8));
      expect(sp.habitAmount, 0);
    });

    test('bedtime / wake time (time of day) become a plain done habit', () {
      for (final metric in [
        HealthMetricType.bedtime,
        HealthMetricType.wakeTime,
      ]) {
        final t = buildTestTemplate(
          healthMetric: metric,
          amount: 22 * 60,
          toleranceMinutes: 30,
        );
        sp.applyPremadeHabitTemplate(t);

        sp.disablePremadeHealthSync(t);

        expect(sp.selectedHealthMetric, isNull);
        expect(sp.selectedHabitTrackingType, isNull);
        expect(sp.habitAmount, 0);
        expect(sp.habitDuration, Duration.zero);
      }
    });
  });
}
