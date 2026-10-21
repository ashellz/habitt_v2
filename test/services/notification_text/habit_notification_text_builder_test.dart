import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/services/habit_notification_text_builder.dart';

import '../../fixtures/habit_factory.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  HabitNotificationContext buildContext(
    Habit habit, {
    required DateTime scheduledAt,
    required HabitAppearsOnDay appearsOnDay,
  }) {
    return HabitNotificationContext(
      habit: habit,
      scheduledAt: scheduledAt,
      appearsOnDay: appearsOnDay,
      localizations: l10n,
      now: scheduledAt.subtract(const Duration(hours: 1)),
    );
  }

  test('evaluates checks and returns a single combined sentence', () {
    final scheduledAt = DateTime(2026, 4, 16, 9, 0);
    final habit = buildTestHabit(
      amount: 10,
      amountCompleted: 8,
      amountLabel: 'dl',
      optional: true,
      trackingType: HabitTrackingType.amount,
      createdAt: DateTime(2026, 4, 13),
    );

    final text = HabitNotificationTextBuilder.build(
      buildContext(
        habit,
        scheduledAt: scheduledAt,
        appearsOnDay: (_, __) => true,
      ),
    );

    expect(
      text.evaluatedChecks,
      containsAll(<String>['premadeType', 'progress', 'schedule', 'freshness']),
    );
    expect(text.selectedSegmentCategories.length, 1);
    expect(text.progressState, HabitNotificationProgressState.almostDone);
    expect(text.scheduleState, HabitNotificationScheduleState.daily);
    expect(text.description, contains('Only'));
    expect(text.description, contains('left'));
  });

  test(
    'uses fallback title, prefixed with the habit icon, when name is empty',
    () {
      final scheduledAt = DateTime(2026, 4, 16, 9, 0);
      final habit = buildTestHabit(name: '   ');

      final text = HabitNotificationTextBuilder.build(
        buildContext(
          habit,
          scheduledAt: scheduledAt,
          appearsOnDay: (_, __) => true,
        ),
      );

      expect(text.title, '${habit.iconPath} ${l10n.notificationFallbackTitle}');
    },
  );

  test('one-off branch overrides progress/freshness branches', () {
    final scheduledAt = DateTime(2026, 4, 19, 21, 0); // Sunday
    final habit = buildTestHabit(
      premadeHabitType: PremadeHabitType.running,
      scheduleType: ScheduleType.weekly,
      weeklyTarget: 2,
      timesCompletedThisWeek: 1,
      amount: 5,
      amountCompleted: 4,
      amountLabel: 'km',
      trackingType: HabitTrackingType.amount,
      createdAt: DateTime(2026, 4, 17),
    );

    final text = HabitNotificationTextBuilder.build(
      buildContext(
        habit,
        scheduledAt: scheduledAt,
        appearsOnDay: (_, __) => true,
      ),
    );

    expect(
      text.scheduleRiskState,
      HabitNotificationScheduleRiskState.atRiskIfSkipToday,
    );
    expect(text.description, contains('last weekly chance'));
    expect(text.description, isNot(contains('Only')));
    expect(text.description, isNot(contains('/')));
  });

  test('picks a single clean variant each time', () {
    final scheduledAt = DateTime(2026, 4, 16, 9, 0);
    final habit = buildTestHabit(
      id: 99,
      premadeHabitType: PremadeHabitType.goToBedEarly,
      scheduleType: ScheduleType.daily,
      trackingType: null,
      amount: 0,
      duration: 0,
    );

    // variants are chosen at random, so look at many picks
    for (var i = 0; i < 40; i++) {
      final text = HabitNotificationTextBuilder.build(
        buildContext(
          habit,
          scheduledAt: scheduledAt,
          appearsOnDay: (_, __) => true,
        ),
      );

      expect(text.description, isNotEmpty);
      // a raw pipe-separated variant list must never reach a notification
      expect(text.description, isNot(contains('|')));
    }
  });

  test(
    'does not use completed-progress text when habit is already complete',
    () {
      final scheduledAt = DateTime(2026, 4, 16, 9, 0);
      final habit = buildTestHabit(
        amount: 10,
        amountCompleted: 10,
        trackingType: HabitTrackingType.amount,
        premadeHabitType: PremadeHabitType.drinkWater,
        createdAt: DateTime(2026, 3, 1),
      );

      final text = HabitNotificationTextBuilder.build(
        buildContext(
          habit,
          scheduledAt: scheduledAt,
          appearsOnDay: (_, __) => true,
        ),
      );

      expect(text.progressState, HabitNotificationProgressState.completed);
      expect(text.description, isNot(contains('Target reached already')));
    },
  );
  test('never leaks pipe-separated variants into the description', () {
    final scheduledAt = DateTime(2026, 4, 16, 9, 0);
    final habits = [
      // Custom habit (e.g. push-ups): no premade type.
      buildTestHabit(
        name: 'Push ups',
        amount: 50,
        amountCompleted: 10,
        amountLabel: 'push-ups',
        trackingType: HabitTrackingType.amount,
        createdAt: DateTime(2026, 3, 1),
      ),
      // Premade types that share the generic encouragement list.
      buildTestHabit(
        amount: 50,
        amountCompleted: 10,
        trackingType: HabitTrackingType.amount,
        premadeHabitType: PremadeHabitType.workoutCombined,
        createdAt: DateTime(2026, 3, 1),
      ),
      buildTestHabit(
        amount: 10000,
        amountCompleted: 0,
        trackingType: HabitTrackingType.amount,
        premadeHabitType: PremadeHabitType.steps,
        createdAt: DateTime(2026, 4, 15),
      ),
    ];

    for (final habit in habits) {
      for (var i = 0; i < 200; i++) {
        final text = HabitNotificationTextBuilder.build(
          buildContext(
            habit,
            scheduledAt: scheduledAt,
            appearsOnDay: (_, __) => true,
          ),
        );
        expect(text.description, isNot(contains('|')));
      }
    }
  });
}
