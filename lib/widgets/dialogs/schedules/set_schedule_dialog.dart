import 'package:flutter/material.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/dialogs/schedules/schedule_dialog_snapshot.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/schedule_option_widget.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class SetScheduleDialog extends StatefulWidget {
  const SetScheduleDialog({super.key, this.rootSnapshot});

  final ScheduleDialogSnapshot? rootSnapshot;

  @override
  State<SetScheduleDialog> createState() => _SetScheduleDialogState();
}

class _SetScheduleDialogState extends State<SetScheduleDialog> {
  late final ScheduleDialogSnapshot rootSnapshot;

  @override
  void initState() {
    super.initState();
    final sp = context.read<StateProvider>();
    rootSnapshot =
        widget.rootSnapshot ?? ScheduleDialogSnapshot.fromStateProvider(sp);
  }

  void _restoreInitialSchedule() {
    final sp = context.read<StateProvider>();
    rootSnapshot.restore(sp);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && result == null) {
          _restoreInitialSchedule();
        }
      },
      child: NewDefaultDialog(
        title: AppLocalizations.of(context)!.setSchedule,
        desc: AppLocalizations.of(context)!.howOftenWouldYouLikeToDoThisHabit,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            for (var option in ScheduleType.values)
              ScheduleOptionWidget(scheduleOptionType: option),
          ],
        ),
        onPrimaryButtonPressed: () {
          final sp = context.read<StateProvider>();
          final cp = context.read<ColorProvider>();
          sp.selectedScheduleOption.handlePrimaryButtonPressed(
            context,
            cp,
            rootSnapshot: rootSnapshot,
          );
        },
        onSecondaryButtonPressed: () {
          _restoreInitialSchedule();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
