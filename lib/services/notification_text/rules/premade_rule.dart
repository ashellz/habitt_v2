import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/services/notification_text/template_catalog.dart';
import 'package:habitt/services/notification_text/types.dart';

class PremadeNotificationRule {
  static HabitNotificationSegment? evaluate(
    HabitNotificationContext context,
    List<String> evaluatedChecks,
  ) {
    evaluatedChecks.add('premadeType');

    final PremadeHabitType? type = context.habit.premadeHabitType;
    if (type == null) {
      return null;
    }

    return HabitNotificationSegment(
      category: HabitNotificationSegmentCategory.identity,
      priority: 120,
      template: NotificationTemplateCatalog.premadeToken(type),
      debugKey: 'premade.${type.name}',
    );
  }
}
