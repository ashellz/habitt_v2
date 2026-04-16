import 'package:habitt/services/notification_text/template_catalog.dart';
import 'package:habitt/services/notification_text/types.dart';

class OptionalNotificationRule {
  static HabitNotificationSegment? evaluate(
    HabitNotificationContext context,
    List<String> evaluatedChecks,
  ) {
    evaluatedChecks.add('optional');

    if (!context.habit.optional) {
      return null;
    }

    return const HabitNotificationSegment(
      category: HabitNotificationSegmentCategory.optional,
      priority: 40,
      template: NotificationTemplateToken(
        key: NotificationTemplateKey.optional,
      ),
      debugKey: 'optional.on',
    );
  }
}
