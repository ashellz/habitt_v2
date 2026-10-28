import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/open_system_notification_settings.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';

// tells the user notifications are turned off for Habitt in the OS, with a
// shortcut to the OS settings where they can turn them on
Future<void> showSystemNotificationsDisabledDialog(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  await showDialogSheet(
    context: context,
    builder:
        (dialogContext) => NewDefaultDialog(
          title: loc.notificationsOffInSystemTitle,
          desc: loc.notificationsOffInSystemDesc,
          primaryButtonLabel: loc.openSettings,
          onPrimaryButtonPressed: () {
            Navigator.of(dialogContext).pop();
            openSystemNotificationSettings();
          },
          onSecondaryButtonPressed: () => Navigator.of(dialogContext).pop(),
        ),
  );
}
