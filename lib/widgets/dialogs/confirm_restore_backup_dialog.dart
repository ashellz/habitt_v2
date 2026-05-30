import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';

class ConfirmRestoreBackupDialog extends StatelessWidget {
  const ConfirmRestoreBackupDialog({super.key, required this.cp});

  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.restoreConfirmTitle,
      desc: loc.restoreConfirmDesc,
      primaryButtonLabel: loc.restore,
      primaryButtonColor: cp.error,
      onPrimaryButtonPressed: () => Navigator.of(context).pop(true),
      secondaryButtonLabel: loc.cancel,
      onSecondaryButtonPressed: () => Navigator.of(context).pop(false),
    );
  }
}
