import 'package:flutter/material.dart';
import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class DeleteNotificationDialog extends StatelessWidget {
  const DeleteNotificationDialog({
    super.key,
    required this.mounted,
    required StatusOverlayPopupController statusOverlay,
    required this.dialogContext,
    required this.slot,
  }) : _statusOverlay = statusOverlay;

  final bool mounted;
  final StatusOverlayPopupController _statusOverlay;
  final BuildContext dialogContext;
  final HabitNotificationTime slot;

  @override
  Widget build(BuildContext context) {
    final cp = context.read<ColorProvider>();
    final sp = context.read<StateProvider>();
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.deleteNotification,
      desc: loc.thisNotificationTimeWillBeRemoved,
      primaryButtonLabel: loc.delete,
      primaryButtonColor: cp.fail,
      onPrimaryButtonPressed: () {
        final removed = sp.removeHabitNotificationTime(slot.id);
        Navigator.of(dialogContext).pop();

        if (!mounted) {
          return;
        }

        _statusOverlay.show(
          context: context,
          cp: cp,
          title:
              removed
                  ? 'Notification deleted'
                  : loc.thisNotificationCantBeDeleted,
          isError: !removed,
        );
      },
    );
  }
}
