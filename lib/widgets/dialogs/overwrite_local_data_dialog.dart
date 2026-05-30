import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class OverwriteLocalDataDialog extends StatelessWidget {
  const OverwriteLocalDataDialog({super.key, required this.onConfirmed});

  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.read<ColorProvider>();

    return NewDefaultDialog(
      title: loc.overwriteLocalDataTitle,
      desc: loc.overwriteLocalDataDesc,
      primaryButtonLabel: loc.overwrite,
      primaryButtonColor: cp.error,
      secondaryButtonLabel: loc.cancel,
      onPrimaryButtonPressed: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        onConfirmed();
      },
    );
  }
}
