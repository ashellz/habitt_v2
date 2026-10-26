import 'package:flutter/material.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/dialogs/schedules/schedule_dialog_snapshot.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_switch.dart';
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
    final loc = AppLocalizations.of(context)!;
    final sp = context.watch<StateProvider>();
    final cp = context.watch<ColorProvider>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && result == null) {
          _restoreInitialSchedule();
        }
      },
      child: NewDefaultDialog(
        title: loc.setSchedule,
        desc: loc.howOftenWouldYouLikeToDoThisHabit,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            for (var option in ScheduleType.values)
              ScheduleOptionWidget(scheduleOptionType: option),
            if (sp.selectedScheduleOption != ScheduleType.daily)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.showIfMissed,
                          style: TextStyle(
                            color: cp.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          loc.showIfMissedDesc,
                          style: TextStyle(color: cp.greyText, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  NewDefaultSwitch(
                    value: sp.showIfMissed,
                    onChanged: (value) => sp.showIfMissed = value,
                  ),
                ],
              ),
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
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
