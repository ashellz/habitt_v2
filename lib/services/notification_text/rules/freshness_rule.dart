import 'package:habitt/services/notification_text/template_catalog.dart';
import 'package:habitt/services/notification_text/types.dart';

class FreshnessRuleResult {
  const FreshnessRuleResult({required this.state, required this.segment});

  final HabitNotificationFreshnessState state;
  final HabitNotificationSegment segment;
}

class FreshnessNotificationRule {
  static FreshnessRuleResult evaluate(
    HabitNotificationContext context,
    List<String> evaluatedChecks,
  ) {
    evaluatedChecks.add('freshness');

    final days = context.daysSinceCreated;
    if (days <= 1) {
      return const FreshnessRuleResult(
        state: HabitNotificationFreshnessState.brandNew,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.freshness,
          priority: 74,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.freshnessBrandNew,
          ),
          debugKey: 'freshness.brandNew',
        ),
      );
    }

    if (days <= 7) {
      return FreshnessRuleResult(
        state: HabitNotificationFreshnessState.newHabit,
        segment: HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.freshness,
          priority: 72,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.freshnessNewDays,
            args: {'days': days + 1},
          ),
          debugKey: 'freshness.newHabit',
        ),
      );
    }

    return FreshnessRuleResult(
      state: HabitNotificationFreshnessState.established,
      segment: HabitNotificationSegment(
        category: HabitNotificationSegmentCategory.freshness,
        priority: 50,
        template: NotificationTemplateToken(
          key: NotificationTemplateKey.freshnessEstablishedDays,
          args: {'days': days},
        ),
        debugKey: 'freshness.established',
      ),
    );
  }
}
