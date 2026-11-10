import 'dart:io';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/notification/alarm_dnd_setting.dart';
import 'package:provider/provider.dart';

/// Asks once (Android, the first time any habit's alarm is turned on) whether
/// alarms should ring during Do Not Disturb, with the same selector as the
/// notification settings page. Does nothing on later calls or other platforms.
Future<void> maybeShowAlarmDndDialog(BuildContext context) async {
  if (!Platform.isAndroid) return;
  final np = context.read<NotificationsProvider>();
  if (np.alarmDndAsked) return;
  await np.markAlarmDndAsked();
  if (!context.mounted) return;

  final loc = AppLocalizations.of(context)!;
  var ringDuringDnd = np.alarmRingDuringDnd;
  await showDialogSheet(
    context: context,
    builder:
        (dialogContext) => StatefulBuilder(
          builder: (context, setState) {
            final cp = context.watch<ColorProvider>();
            return NewDefaultDialog(
              title: loc.alarmDndDialogTitle,
              tip: loc.alarmDndDialogTip,
              showSecondaryButton: false,
              primaryButtonLabel: loc.done,
              onPrimaryButtonPressed: () => Navigator.of(dialogContext).pop(),
              child: AlarmDndSetting(
                ringDuringDnd: ringDuringDnd,
                // the dialog itself has the settings card colour
                color: cp.field,
                selectorColor: cp.isDark ? cp.habitBg : cp.bg,
                onChanged: (value) => setState(() => ringDuringDnd = value),
              ),
            );
          },
        ),
  );
  // closing the dialog any way keeps the choice shown in it
  if (ringDuringDnd != np.alarmRingDuringDnd) {
    await np.setAlarmRingDuringDnd(ringDuringDnd);
  }
}
