import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

/// Confirmation before the backup found in the cloud is thrown away and
/// replaced by this device's data ("Ignore backup and upload mine").
class ReplaceCloudBackupDialog extends StatelessWidget {
  const ReplaceCloudBackupDialog({
    super.key,
    required this.cloudName,
    required this.onConfirmed,
  });

  final String cloudName;
  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.read<ColorProvider>();

    return NewDefaultDialog(
      title: loc.replaceCloudBackupTitle,
      desc: loc.replaceCloudBackupDesc(cloudName),
      primaryButtonLabel: loc.replaceCloudBackup,
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
