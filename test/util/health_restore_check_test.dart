import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/util/health_restore_check.dart';

import '../fixtures/habit_factory.dart';

void main() {
  final steps = buildTestHabit(id: 1, healthMetric: HealthMetricType.steps);
  final mindful = buildTestHabit(
    id: 2,
    healthMetric: HealthMetricType.mindfulness,
  );
  final plain = buildTestHabit(id: 3);
  final deleted = buildTestHabit(id: 4, healthMetric: HealthMetricType.sleep)
    ..isDeleted = true;
  final all = [steps, mindful, plain, deleted];

  test('an Android phone tracks everything but the iOS-only metrics', () {
    final check = checkRestoredHealthHabits(all, canRead: (m) => !m.isIosOnly);
    expect(check.trackable, [steps]);
    expect(check.untrackable, [mindful]);
  });

  test('a phone without Health tracks none of them', () {
    final check = checkRestoredHealthHabits(all, canRead: (_) => false);
    expect(check.trackable, isEmpty);
    expect(check.untrackable, [steps, mindful]);
  });

  test('plain and deleted habits are left out', () {
    final check = checkRestoredHealthHabits([
      plain,
      deleted,
    ], canRead: (_) => true);
    expect(check.hasHealthHabits, isFalse);
  });
}
