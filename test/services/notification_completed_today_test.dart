import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/services/notification_service.dart';

import '../fixtures/habit_factory.dart';

void main() {
  final now = DateTime(2026, 11, 4, 15, 0);

  test('completed and stamped today counts as done today', () {
    final habit = buildTestHabit(
      timestamps: {'completed': DateTime(2026, 11, 4, 8, 30).toUtc()},
    )..completed = true;

    expect(NotificationService.isCompletedToday(habit, now), isTrue);
  });

  test('not completed is never done today', () {
    final habit = buildTestHabit(
      timestamps: {'completed': DateTime(2026, 11, 4, 8, 30).toUtc()},
    )..completed = false;

    expect(NotificationService.isCompletedToday(habit, now), isFalse);
  });

  test('completion left over from yesterday does not hide today', () {
    // app opened on a new day, scheduling before the rollover reset
    final habit = buildTestHabit(
      timestamps: {'completed': DateTime(2026, 11, 3, 22, 0).toUtc()},
    )..completed = true;

    expect(NotificationService.isCompletedToday(habit, now), isFalse);
  });

  test('completion without a stamp keeps the reminders', () {
    final habit = buildTestHabit()..completed = true;

    expect(NotificationService.isCompletedToday(habit, now), isFalse);
  });
}
