import 'dart:math' as math;

import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/services/notification_text/template_catalog.dart';
import 'package:habitt/services/notification_text/types.dart';

class ScheduleRuleResult {
  const ScheduleRuleResult({
    required this.state,
    required this.riskState,
    required this.segment,
  });

  final HabitNotificationScheduleState state;
  final HabitNotificationScheduleRiskState riskState;
  final HabitNotificationSegment segment;
}

class ScheduleNotificationRule {
  static ScheduleRuleResult evaluate(
    HabitNotificationContext context,
    List<String> evaluatedChecks,
  ) {
    evaluatedChecks.add('schedule');

    switch (context.habit.scheduleType) {
      case ScheduleType.daily:
        return const ScheduleRuleResult(
          state: HabitNotificationScheduleState.daily,
          riskState: HabitNotificationScheduleRiskState.none,
          segment: HabitNotificationSegment(
            category: HabitNotificationSegmentCategory.schedule,
            priority: 86,
            template: NotificationTemplateToken(
              key: NotificationTemplateKey.scheduleDaily,
            ),
            debugKey: 'schedule.daily',
          ),
        );
      case ScheduleType.custom:
        final everyDays = math.max(1, context.habit.customIntervalDays);
        return ScheduleRuleResult(
          state: HabitNotificationScheduleState.custom,
          riskState: HabitNotificationScheduleRiskState.none,
          segment: HabitNotificationSegment(
            category: HabitNotificationSegmentCategory.schedule,
            priority: 84,
            template: NotificationTemplateToken(
              key: NotificationTemplateKey.scheduleCustomEveryDays,
              args: {'days': everyDays},
            ),
            debugKey: 'schedule.custom',
          ),
        );
      case ScheduleType.weekly:
        return _weekly(context);
      case ScheduleType.monthly:
        return _monthly(context);
    }
  }

  static ScheduleRuleResult _weekly(HabitNotificationContext context) {
    final target = math.max(1, context.habit.weeklyTarget);
    final completed = _effectiveTimesCompletedThisWeek(
      context.habit,
      context.scheduledDay,
    );
    final remaining = math.max(0, target - completed);

    if (remaining == 0) {
      return ScheduleRuleResult(
        state: HabitNotificationScheduleState.weeklyGoalReached,
        riskState: HabitNotificationScheduleRiskState.alreadyReached,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.schedule,
          priority: 58,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.scheduleWeeklyReached,
            args: {'completed': completed, 'target': target},
          ),
          debugKey: 'schedule.weekly.reached',
        ),
      );
    }

    final opportunities = _countWeeklyOpportunitiesFromDay(context);
    if (opportunities < remaining) {
      return ScheduleRuleResult(
        state: HabitNotificationScheduleState.weeklyImpossible,
        riskState: HabitNotificationScheduleRiskState.impossibleEvenIfDoneToday,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.schedule,
          priority: 116,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.scheduleWeeklyImpossible,
            args: {
              'remaining': remaining,
              'completed': completed,
              'target': target,
            },
          ),
          debugKey: 'schedule.weekly.impossible',
        ),
      );
    }

    final opportunitiesAfterSkip = math.max(0, opportunities - 1);
    if (opportunitiesAfterSkip < remaining) {
      return ScheduleRuleResult(
        state: HabitNotificationScheduleState.weeklyLastWindow,
        riskState: HabitNotificationScheduleRiskState.atRiskIfSkipToday,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.schedule,
          priority: 112,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.scheduleWeeklyAtRisk,
            args: {
              'remaining': remaining,
              'completed': completed,
              'target': target,
            },
          ),
          debugKey: 'schedule.weekly.atRisk',
        ),
      );
    }

    if (remaining == 1) {
      return ScheduleRuleResult(
        state: HabitNotificationScheduleState.weeklyOnTrack,
        riskState: HabitNotificationScheduleRiskState.onTrack,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.schedule,
          priority: 92,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.scheduleWeeklyOneLeft,
            args: {'completed': completed, 'target': target},
          ),
          debugKey: 'schedule.weekly.oneLeft',
        ),
      );
    }

    return ScheduleRuleResult(
      state: HabitNotificationScheduleState.weeklyOnTrack,
      riskState: HabitNotificationScheduleRiskState.onTrack,
      segment: HabitNotificationSegment(
        category: HabitNotificationSegmentCategory.schedule,
        priority: 89,
        template: NotificationTemplateToken(
          key: NotificationTemplateKey.scheduleWeeklyRemaining,
          args: {'remaining': remaining, 'target': target},
        ),
        debugKey: 'schedule.weekly.remaining',
      ),
    );
  }

  static ScheduleRuleResult _monthly(HabitNotificationContext context) {
    final target = math.max(1, context.habit.monthlyTarget);
    final completed = _effectiveTimesCompletedThisMonth(
      context.habit,
      context.scheduledDay,
    );
    final remaining = math.max(0, target - completed);

    if (remaining == 0) {
      return ScheduleRuleResult(
        state: HabitNotificationScheduleState.monthlyGoalReached,
        riskState: HabitNotificationScheduleRiskState.alreadyReached,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.schedule,
          priority: 58,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.scheduleMonthlyReached,
            args: {'completed': completed, 'target': target},
          ),
          debugKey: 'schedule.monthly.reached',
        ),
      );
    }

    final opportunities = _countMonthlyOpportunitiesFromDay(context);
    if (opportunities < remaining) {
      return ScheduleRuleResult(
        state: HabitNotificationScheduleState.monthlyImpossible,
        riskState: HabitNotificationScheduleRiskState.impossibleEvenIfDoneToday,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.schedule,
          priority: 116,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.scheduleMonthlyImpossible,
            args: {
              'remaining': remaining,
              'completed': completed,
              'target': target,
            },
          ),
          debugKey: 'schedule.monthly.impossible',
        ),
      );
    }

    final opportunitiesAfterSkip = math.max(0, opportunities - 1);
    if (opportunitiesAfterSkip < remaining) {
      return ScheduleRuleResult(
        state: HabitNotificationScheduleState.monthlyLastWindow,
        riskState: HabitNotificationScheduleRiskState.atRiskIfSkipToday,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.schedule,
          priority: 112,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.scheduleMonthlyAtRisk,
            args: {
              'remaining': remaining,
              'completed': completed,
              'target': target,
            },
          ),
          debugKey: 'schedule.monthly.atRisk',
        ),
      );
    }

    if (remaining == 1) {
      return ScheduleRuleResult(
        state: HabitNotificationScheduleState.monthlyOnTrack,
        riskState: HabitNotificationScheduleRiskState.onTrack,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.schedule,
          priority: 92,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.scheduleMonthlyOneLeft,
            args: {'completed': completed, 'target': target},
          ),
          debugKey: 'schedule.monthly.oneLeft',
        ),
      );
    }

    return ScheduleRuleResult(
      state: HabitNotificationScheduleState.monthlyOnTrack,
      riskState: HabitNotificationScheduleRiskState.onTrack,
      segment: HabitNotificationSegment(
        category: HabitNotificationSegmentCategory.schedule,
        priority: 89,
        template: NotificationTemplateToken(
          key: NotificationTemplateKey.scheduleMonthlyRemaining,
          args: {'remaining': remaining, 'target': target},
        ),
        debugKey: 'schedule.monthly.remaining',
      ),
    );
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int _weekKey(DateTime date) {
    final normalized = _normalizeDate(date);
    final monday = normalized.subtract(Duration(days: normalized.weekday - 1));
    final startOfYear = DateTime(monday.year, 1, 1);
    final dayOfYear = monday.difference(startOfYear).inDays + 1;
    return (monday.year * 1000) + dayOfYear;
  }

  static int _effectiveTimesCompletedThisWeek(Habit habit, DateTime day) {
    final ts = habit.timestamps['timesCompletedThisWeek'];
    if (ts == null) {
      return habit.timesCompletedThisWeek;
    }

    final timestampLocal = ts.toLocal();
    return _weekKey(timestampLocal) == _weekKey(day)
        ? habit.timesCompletedThisWeek
        : 0;
  }

  static int _effectiveTimesCompletedThisMonth(Habit habit, DateTime day) {
    final ts = habit.timestamps['timesCompletedThisMonth'];
    if (ts == null) {
      return habit.timesCompletedThisMonth;
    }

    final timestampLocal = ts.toLocal();
    final sameMonth =
        timestampLocal.year == day.year && timestampLocal.month == day.month;
    return sameMonth ? habit.timesCompletedThisMonth : 0;
  }

  static int _countWeeklyOpportunitiesFromDay(
    HabitNotificationContext context,
  ) {
    final day = context.scheduledDay;
    final weekStart = day.subtract(Duration(days: day.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    int opportunities = 0;
    for (
      DateTime cursor = day;
      !cursor.isAfter(weekEnd);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      if (context.appearsOnDay(context.habit, cursor)) {
        opportunities += 1;
      }
    }

    return opportunities;
  }

  static int _countMonthlyOpportunitiesFromDay(
    HabitNotificationContext context,
  ) {
    final day = context.scheduledDay;
    final monthEnd = DateTime(day.year, day.month + 1, 0);

    int opportunities = 0;
    for (
      DateTime cursor = day;
      !cursor.isAfter(monthEnd);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      if (context.appearsOnDay(context.habit, cursor)) {
        opportunities += 1;
      }
    }

    return opportunities;
  }
}
