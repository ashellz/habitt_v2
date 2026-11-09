import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_workout_type.dart';
import 'package:habitt/util/health_editor_fields.dart';

import '../fixtures/habit_factory.dart';

Habit _linked() => buildTestHabit(
  amount: 1,
  amountLabel: 'workouts',
  duration: 1800,
  trackingType: HabitTrackingType.duration,
  healthMetric: HealthMetricType.workouts,
  healthWorkoutFilter: HealthWorkoutType.values.first,
  healthBedtimeDayBefore: true,
  toleranceMinutes: 30,
);

// what the sheet would write from an editor whose Health section was hidden
// and whose state somehow didn't match the habit (e.g. cleared)
void _editorClears(Habit habit) {
  habit.healthMetric = null;
  habit.healthWorkoutFilter = null;
  habit.healthBedtimeDayBefore = false;
  habit.toleranceMinutes = 0;
  habit.trackingType = null;
  habit.amount = 0;
  habit.duration = 0;
  habit.amountLabel = '';
}

void main() {
  test('a hidden Health section never unlinks or retargets the habit', () {
    final original = _linked();
    final edited = original.copy()..name = 'Gym';
    _editorClears(edited);

    keepHiddenHealthFields(edited, original: original, editorShown: false);

    expect(edited.name, 'Gym', reason: 'other edits still go through');
    expect(edited.healthMetric, HealthMetricType.workouts);
    expect(edited.healthWorkoutFilter, original.healthWorkoutFilter);
    expect(edited.healthBedtimeDayBefore, isTrue);
    expect(edited.toleranceMinutes, 30);
    expect(edited.trackingType, HabitTrackingType.duration);
    expect(edited.amount, 1);
    expect(edited.duration, 1800);
    expect(edited.amountLabel, 'workouts');
  });

  test('a shown section saves what the user chose, unlinking included', () {
    final original = _linked();
    final edited = original.copy();
    _editorClears(edited);

    keepHiddenHealthFields(edited, original: original, editorShown: true);

    expect(edited.healthMetric, isNull);
    expect(edited.amount, 0);
  });

  test('a habit that is not linked keeps the editor values', () {
    final original = buildTestHabit(amount: 10);
    final edited = original.copy()..amount = 12;

    keepHiddenHealthFields(edited, original: original, editorShown: false);

    expect(edited.amount, 12);
    expect(edited.healthMetric, isNull);
  });

  test('an unchanged save gives the Health fields no new timestamp', () {
    final original = _linked();
    final edited = original.copy();
    keepHiddenHealthFields(edited, original: original, editorShown: false);

    final stored = original.copy();
    stored.updateHabit(edited);
    for (final key in ['healthMetric', 'amount', 'duration', 'trackingType']) {
      expect(stored.timestamps[key], original.timestamps[key], reason: key);
    }
  });
}
