import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/format_backup_date.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class OverwriteLocalDataDialog extends StatelessWidget {
  const OverwriteLocalDataDialog({
    super.key,
    required this.onConfirmed,
    this.backupTime,
  });

  final VoidCallback onConfirmed;

  /// When known, the date of the backup that will replace local data.
  final DateTime? backupTime;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.read<ColorProvider>();

    return NewDefaultDialog(
      title: loc.overwriteLocalDataTitle,
      desc:
          backupTime != null
              ? loc.overwriteLocalDataDescWithDate(
                formatBackupDate(backupTime!, loc),
              )
              : loc.overwriteLocalDataDesc,
      primaryButtonLabel: loc.delete,
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
