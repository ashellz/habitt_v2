import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';

class UnencryptedWarningDialog extends StatelessWidget {
  const UnencryptedWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return NewDefaultDialog(
      title: loc.exportUnencryptedWarningTitle,
      desc: loc.exportUnencryptedWarningDesc,
      primaryButtonLabel: loc.exportUnencryptedConfirm,
      secondaryButtonLabel: loc.cancel,
      onPrimaryButtonPressed: () => Navigator.of(context).pop(true),
      onSecondaryButtonPressed: () => Navigator.of(context).pop(false),
    );
  }
}
