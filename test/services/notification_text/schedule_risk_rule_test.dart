import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
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
      now: scheduledAt.subtract(const Duration(minutes: 1)),
    );
  }

  test('weekly target becomes at risk when skipping today', () {
    final scheduledAt = DateTime(2026, 4, 16, 9, 0);
    final habit = buildTestHabit(
      scheduleType: ScheduleType.weekly,
      weeklyTarget: 2,
      timesCompletedThisWeek: 0,
      amount: 1,
      amountCompleted: 0,
      trackingType: HabitTrackingType.amount,
      timestamps: {'timesCompletedThisWeek': DateTime(2026, 4, 14).toUtc()},
    );

    bool appearsOnDay(Habit _, DateTime day) {
      final normalized = DateTime(day.year, day.month, day.day);
      final base = DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
      );
      final diff = normalized.difference(base).inDays;
      return diff == 0 || diff == 1;
    }

    final text = HabitNotificationTextBuilder.build(
      buildContext(habit, scheduledAt: scheduledAt, appearsOnDay: appearsOnDay),
    );

    expect(
      text.scheduleRiskState,
      HabitNotificationScheduleRiskState.atRiskIfSkipToday,
    );
    expect(text.scheduleState, HabitNotificationScheduleState.weeklyLastWindow);
  });

  test('weekly target can become impossible even if done today', () {
    final scheduledAt = DateTime(2026, 4, 16, 9, 0);
    final habit = buildTestHabit(
      scheduleType: ScheduleType.weekly,
      weeklyTarget: 2,
      timesCompletedThisWeek: 0,
      amount: 1,
      amountCompleted: 0,
      trackingType: HabitTrackingType.amount,
      timestamps: {'timesCompletedThisWeek': DateTime(2026, 4, 14).toUtc()},
    );

    bool appearsOnDay(Habit _, DateTime day) {
      final normalized = DateTime(day.year, day.month, day.day);
      final base = DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
      );
      final diff = normalized.difference(base).inDays;
      return diff == 0;
    }

    final text = HabitNotificationTextBuilder.build(
      buildContext(habit, scheduledAt: scheduledAt, appearsOnDay: appearsOnDay),
    );

    expect(
      text.scheduleRiskState,
      HabitNotificationScheduleRiskState.impossibleEvenIfDoneToday,
    );
    expect(text.scheduleState, HabitNotificationScheduleState.weeklyImpossible);
  });

  test('monthly target can be flagged as at risk if skipped today', () {
    final scheduledAt = DateTime(2026, 4, 10, 9, 0);
    final habit = buildTestHabit(
      scheduleType: ScheduleType.monthly,
      monthlyTarget: 3,
      timesCompletedThisMonth: 0,
      amount: 1,
      amountCompleted: 0,
      trackingType: HabitTrackingType.amount,
      timestamps: {'timesCompletedThisMonth': DateTime(2026, 4, 1).toUtc()},
    );

    bool appearsOnDay(Habit _, DateTime day) {
      final normalized = DateTime(day.year, day.month, day.day);
      final base = DateTime(
        scheduledAt.year,
        scheduledAt.month,
        scheduledAt.day,
      );
      final diff = normalized.difference(base).inDays;
      return diff >= 0 && diff <= 2;
    }

    final text = HabitNotificationTextBuilder.build(
      buildContext(habit, scheduledAt: scheduledAt, appearsOnDay: appearsOnDay),
    );

    expect(
      text.scheduleRiskState,
      HabitNotificationScheduleRiskState.atRiskIfSkipToday,
    );
    expect(
      text.scheduleState,
      HabitNotificationScheduleState.monthlyLastWindow,
    );
  });
}
