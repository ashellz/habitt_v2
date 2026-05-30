import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/overwrite_local_data_dialog.dart';
import 'package:provider/provider.dart';

class RestoreChoiceDialog extends StatefulWidget {
  const RestoreChoiceDialog({super.key});

  @override
  State<RestoreChoiceDialog> createState() => _RestoreChoiceDialogState();
}

class _RestoreChoiceDialogState extends State<RestoreChoiceDialog> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bp = context.read<BackupProvider>();

    return NewDefaultDialog(
      title: loc.backupFound,
      desc:
          loc.backupFoundDesc, // 'Your Google Drive has a backup. How would you like to restore?',
      primaryButtonLabel: loc.merge, // Merge
      secondaryButtonLabel: loc.delete,
      onPrimaryButtonPressed: () async {
        bp.confirmMerge();
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      onSecondaryButtonPressed: () {
        if (!context.mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => OverwriteLocalDataDialog(
            onConfirmed: () {
              final bp = context.read<BackupProvider>();
              bp.confirmReplace();
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        );
      },
    );
  }
}
