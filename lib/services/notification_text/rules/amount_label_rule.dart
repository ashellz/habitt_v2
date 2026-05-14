import 'package:habitt/services/notification_text/template_catalog.dart';
import 'package:habitt/services/notification_text/types.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';

class AmountLabelNotificationRule {
  static HabitNotificationSegment? evaluate(
    HabitNotificationContext context,
    List<String> evaluatedChecks,
  ) {
    final l = context.localizations;
    evaluatedChecks.add('amountLabel');

    final habit = context.habit;
    if (!habit.tracksAmount || habit.amount <= 0) {
      return null;
    }

    final label = resolveAmountLabelForValue(
      habit.amountLabel,
      habit.amount,
      l,
    );
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'time' || normalized == 'times') {
      return null;
    }

    return HabitNotificationSegment(
      category: HabitNotificationSegmentCategory.amountLabel,
      priority: 62,
      template: NotificationTemplateToken(
        key: NotificationTemplateKey.amountLabelFocus,
        args: {'target': habit.amount, 'label': label},
      ),
      debugKey: 'amountLabel.focus',
    );
  }
}
