import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/premade_habit_catalog.dart';
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
    bool? saved,
  }) => decidePremadeHealthPrompt(
    template: hasMetric ? steps : buildTestTemplate(amount: 1),
    isAvailable: available,
    isMetricSupported: supported,
    savedSync: saved,
  );

  group('decidePremadeHealthPrompt', () {
    test('a template without a Health metric never asks', () {
      expect(decide(hasMetric: false), PremadeHealthDecision.notHealthLinked);
    });

    test('asks while the user has never decided', () {
      expect(decide(), PremadeHealthDecision.ask);
    });

    test('setting on links Health without asking', () {
      expect(decide(saved: true), PremadeHealthDecision.useHealth);
    });

    test('setting off opens manual without asking', () {
      expect(decide(saved: false), PremadeHealthDecision.useManual);
    });

    test('unavailable Health or unsupported metric is manual, set or not', () {
      for (final saved in [null, true, false]) {
        expect(
          decide(available: false, saved: saved),
          PremadeHealthDecision.manualOnly,
        );
        expect(
          decide(supported: false, saved: saved),
          PremadeHealthDecision.manualOnly,
        );
      }
    });

    test('every Health premade in the catalog asks only until decided', () {
      var count = 0;
      for (final section in PremadeHabitCatalog.sections) {
        for (final t in section.habits) {
          if (t.defaultHealthMetric == null) continue;
          count++;
          PremadeHealthDecision d(bool? saved) => decidePremadeHealthPrompt(
            template: t,
            isAvailable: true,
            isMetricSupported: true,
            savedSync: saved,
          );
          expect(d(null), PremadeHealthDecision.ask, reason: t.type.name);
          expect(d(true), PremadeHealthDecision.useHealth, reason: t.type.name);
          expect(
            d(false),
            PremadeHealthDecision.useManual,
            reason: t.type.name,
          );
        }
      }
      expect(count, greaterThan(0));
    });
  });

  group('saved setting', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is null until decided, then keeps whatever was saved', () async {
      expect(await loadPremadeHealthSync(), isNull);
      await savePremadeHealthSync(false);
      expect(await loadPremadeHealthSync(), isFalse);
      await savePremadeHealthSync(true);
      expect(await loadPremadeHealthSync(), isTrue);
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
