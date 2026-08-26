import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/number_picker.dart';

/// A minimal clock-time picker for a single Health target (bedtime/wake
/// time) — the same in-app wheel (`NumberPicker`) that drives habit
/// notification times, without the weekday/"follow schedule" chrome
/// `showNotificationTimeDialog` carries (irrelevant for a Health target).
///
/// [initialMinutes] and the value passed to [onSaved] are plain
/// minutes-since-midnight (0-1439, wall-clock — not the ">1440 for the
/// small hours" storage convention some callers use for bedtime; callers
/// apply that conversion themselves on the raw hour/minute).
Future<void> showHealthTimeOfDayDialog({
  required BuildContext context,
  required int initialMinutes,
  required String title,
  required ValueChanged<int> onSaved,
}) async {
  int selectedHour = (initialMinutes ~/ 60) % 24;
  int selectedMinute = initialMinutes % 60;

  final hoursController = FixedExtentScrollController(
    initialItem: selectedHour,
  );
  final minutesController = FixedExtentScrollController(
    initialItem: selectedMinute,
  );
  final loc = AppLocalizations.of(context)!;

  try {
    await showDialogSheet(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return NewDefaultDialog(
                title: title,
                primaryButtonLabel: loc.save,
                onPrimaryButtonPressed: () {
                  onSaved((selectedHour * 60) + selectedMinute);
                  Navigator.of(dialogContext).pop();
                },
                child: NumberPicker(
                  hoursController: hoursController,
                  minutesController: minutesController,
                  width: MediaQuery.of(dialogContext).size.width,
                  onChangedHours: (value) {
                    setDialogState(() {
                      selectedHour = value;
                    });
                  },
                  onChangedMinutes: (value) {
                    setDialogState(() {
                      selectedMinute = value;
                    });
                  },
                ),
              );
            },
          ),
    );
  } finally {
    hoursController.dispose();
    minutesController.dispose();
  }
}
