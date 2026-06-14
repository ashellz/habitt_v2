import 'dart:math' as math;

import 'package:habitt/services/notification_text/template_catalog.dart';
import 'package:habitt/services/notification_text/types.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';

class ProgressRuleResult {
  const ProgressRuleResult({required this.state, required this.segment});

  final HabitNotificationProgressState state;
  final HabitNotificationSegment segment;
}

class ProgressNotificationRule {
  static ProgressRuleResult evaluate(
    HabitNotificationContext context,
    List<String> evaluatedChecks,
  ) {
    final l = context.localizations;
    evaluatedChecks.add('progress');

    final habit = context.habit;

    if (habit.tracksAmount && habit.amount > 0) {
      final completed = habit.amountCompleted.clamp(0, habit.amount);
      final remaining = math.max(0, habit.amount - completed);
      final label = resolveAmountLabelForValue(
        habit.amountLabel,
        remaining,
        l,
        customSingulars: context.customSingulars,
      );

      if (completed <= 0) {
        return ProgressRuleResult(
          state: HabitNotificationProgressState.notStarted,
          segment: HabitNotificationSegment(
            category: HabitNotificationSegmentCategory.progress,
            priority: 90,
            template: NotificationTemplateToken(
              key: NotificationTemplateKey.progressNotStartedAmount,
              args: {'label': label},
            ),
            debugKey: 'progress.amount.notStarted',
          ),
        );
      }

      if (remaining == 0) {
        return ProgressRuleResult(
          state: HabitNotificationProgressState.completed,
          segment: HabitNotificationSegment(
            category: HabitNotificationSegmentCategory.progress,
            priority: 55,
            template: NotificationTemplateToken(
              key: NotificationTemplateKey.progressCompletedAmount,
              args: {
                'completed': completed,
                'label': resolveAmountLabelForValue(
                  habit.amountLabel,
                  completed,
                  l,
                  customSingulars: context.customSingulars,
                ),
              },
            ),
            debugKey: 'progress.amount.completed',
          ),
        );
      }

      if (remaining == 1 || remaining <= _almostDoneThreshold(habit.amount)) {
        return ProgressRuleResult(
          state: HabitNotificationProgressState.almostDone,
          segment: HabitNotificationSegment(
            category: HabitNotificationSegmentCategory.progress,
            priority: 110,
            template: NotificationTemplateToken(
              key: NotificationTemplateKey.progressAlmostDoneAmount,
              args: {'remaining': remaining, 'label': label},
            ),
            debugKey: 'progress.amount.almostDone',
          ),
        );
      }

      return ProgressRuleResult(
        state: HabitNotificationProgressState.inProgress,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.progress,
          priority: 82,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.progressInProgressAmount,
            args: {
              'completed': completed,
              'target': habit.amount,
              'label': resolveAmountLabelForValue(
                habit.amountLabel,
                habit.amount,
                l,
                customSingulars: context.customSingulars,
              ),
            },
          ),
          debugKey: 'progress.amount.inProgress',
        ),
      );
    }

    if (habit.tracksDuration && habit.duration > 0) {
      final completed = habit.durationCompleted.clamp(0, habit.duration);
      final remaining = math.max(0, habit.duration - completed);

      if (completed <= 0) {
        return ProgressRuleResult(
          state: HabitNotificationProgressState.notStarted,
          segment: HabitNotificationSegment(
            category: HabitNotificationSegmentCategory.progress,
            priority: 90,
            template: const NotificationTemplateToken(
              key: NotificationTemplateKey.progressNotStartedDuration,
            ),
            debugKey: 'progress.duration.notStarted',
          ),
        );
      }

      if (remaining == 0) {
        return ProgressRuleResult(
          state: HabitNotificationProgressState.completed,
          segment: HabitNotificationSegment(
            category: HabitNotificationSegmentCategory.progress,
            priority: 55,
            template: NotificationTemplateToken(
              key: NotificationTemplateKey.progressCompletedDuration,
              args: {'completed': _formatDuration(completed)},
            ),
            debugKey: 'progress.duration.completed',
          ),
        );
      }

      if (remaining <= _almostDoneThreshold(habit.duration)) {
        return ProgressRuleResult(
          state: HabitNotificationProgressState.almostDone,
          segment: HabitNotificationSegment(
            category: HabitNotificationSegmentCategory.progress,
            priority: 110,
            template: NotificationTemplateToken(
              key: NotificationTemplateKey.progressAlmostDoneDuration,
              args: {'remaining': _formatDuration(remaining)},
            ),
            debugKey: 'progress.duration.almostDone',
          ),
        );
      }

      return ProgressRuleResult(
        state: HabitNotificationProgressState.inProgress,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.progress,
          priority: 82,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.progressInProgressDuration,
            args: {
              'completed': _formatDuration(completed),
              'target': _formatDuration(habit.duration),
            },
          ),
          debugKey: 'progress.duration.inProgress',
        ),
      );
    }

    return ProgressRuleResult(
      state: HabitNotificationProgressState.noTrackingGoal,
      segment: const HabitNotificationSegment(
        category: HabitNotificationSegmentCategory.progress,
        priority: 70,
        template: NotificationTemplateToken(
          key: NotificationTemplateKey.progressNoTracking,
        ),
        debugKey: 'progress.noTracking',
      ),
    );
  }

  static int _almostDoneThreshold(int target) {
    return math.max(1, (target * 0.2).ceil());
  }

  static String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (remainder == 0) {
      return '$hours h';
    }
    return '$hours h $remainder min';
  }
}
