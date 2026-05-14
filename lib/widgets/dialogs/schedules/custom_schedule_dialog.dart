import 'package:flutter/material.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/increment_decrement_text_field.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/schedule_dialog_snapshot.dart';
import 'package:habitt/widgets/dialogs/schedules/set_schedule_dialog.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class CustomScheduleDialog extends StatefulWidget {
  const CustomScheduleDialog({super.key, required this.rootSnapshot});

  final ScheduleDialogSnapshot rootSnapshot;

  @override
  State<CustomScheduleDialog> createState() => _CustomScheduleDialogState();
}

class _CustomScheduleDialogState extends State<CustomScheduleDialog> {
  late int initialCustomIntervalDays;
  late final TextEditingController customIntervalController;

  @override
  void initState() {
    super.initState();
    final sp = context.read<StateProvider>();
    initialCustomIntervalDays = sp.customIntervalDays;
    customIntervalController = TextEditingController(
      text: sp.customIntervalDays.toString(),
    );
  }

  @override
  void dispose() {
    customIntervalController.dispose();
    super.dispose();
  }

  bool _hasUnsavedChanges(StateProvider sp) {
    return sp.customIntervalDays != initialCustomIntervalDays;
  }

  void _returnToSetSchedule(ColorProvider cp) {
    Navigator.of(context).pop();
    showDialogSheet(
      context: context,
      builder:
          (context) => SetScheduleDialog(rootSnapshot: widget.rootSnapshot),
    );
  }

  Future<void> _handleExitAttempt(StateProvider sp, ColorProvider cp) async {
    if (!_hasUnsavedChanges(sp)) {
      _returnToSetSchedule(cp);
      return;
    }
    final loc = AppLocalizations.of(context)!;
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => NewDefaultDialog(
            title: loc.exitWithoutSaving,
            primaryButtonLabel: loc.exit,
            onPrimaryButtonPressed: () {
              sp.customIntervalDays = initialCustomIntervalDays;
              Navigator.of(dialogContext).pop();
              _returnToSetSchedule(cp);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StateProvider>();
    final loc = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && result == null) {
          _handleExitAttempt(sp, cp);
        }
      },
      child: NewDefaultDialog(
        title: loc.custom,
        onPrimaryButtonPressed: () {
          Navigator.of(context).pop(true);
        },
        onSecondaryButtonPressed: () {
          _handleExitAttempt(sp, cp);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.repeatEvery,
              style: TextStyle(
                color: cp.text,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            IncrementDecrementTextField(
              controller:
                  customIntervalController
                    ..text = sp.customIntervalDays.toString(),
              minValue: 1,
              maxValue: 30,
              onValueChanged: (value) {
                sp.customIntervalDays = value;
              },
              onIncrement: () {
                final next =
                    sp.customIntervalDays == 30 ? 1 : sp.customIntervalDays + 1;
                sp.customIntervalDays = next;
              },
              onDecrement: () {
                final next =
                    sp.customIntervalDays == 1 ? 30 : sp.customIntervalDays - 1;
                sp.customIntervalDays = next;
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                loc.habitWillAppear(loc.day, sp.customIntervalDays),
                style: TextStyle(color: cp.greyText, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
