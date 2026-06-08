import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';

class UseThisPinDialog extends StatelessWidget {
  const UseThisPinDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return NewDefaultDialog(
      title: loc.useThisPinQuestion,
      primaryButtonLabel: loc.savePin,
      secondaryButtonLabel: loc.notNow,
      onPrimaryButtonPressed: () => Navigator.of(context).pop(true),
      onSecondaryButtonPressed: () => Navigator.of(context).pop(false),
    );
  }
}
