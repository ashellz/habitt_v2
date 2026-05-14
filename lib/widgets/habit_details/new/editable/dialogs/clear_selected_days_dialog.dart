import 'package:flutter/material.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class ClearSelectedDaysDialog extends StatelessWidget {
  const ClearSelectedDaysDialog({
    super.key,
    required this.dialogContext,
    required this.type,
    required this.nextValue,
  });

  final BuildContext dialogContext;
  final ScheduleType type;
  final int nextValue;

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StateProvider>();

    final String habitUnit = type == ScheduleType.weekly ? 'week' : 'month';

    return NewDefaultDialog(
      title: AppLocalizations.of(context)!.clearSelectedDays,
      desc:
          AppLocalizations.of(context)!.changingTheAmountOfTimesHabitAppearsInAHabitunitWillClearSelectedDays,
      primaryButtonLabel: AppLocalizations.of(context)!.clear,
      onPrimaryButtonPressed: () {
        switch (type) {
          case ScheduleType.weekly:
            sp.selectedDaysAWeek = <int>{};
            sp.weeklyTarget = nextValue;
            break;
          case ScheduleType.monthly:
            sp.selectedDaysAMonth = <int>{};
            sp.monthlyTarget = nextValue;
            break;
          default:
            break;
        }

        Navigator.of(dialogContext).pop(true);
      },
      onSecondaryButtonPressed: () {
        Navigator.of(dialogContext).pop(false);
      },
    );
  }
}
