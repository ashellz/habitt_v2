import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/overwrite_local_data_dialog.dart';
import 'package:habitt/widgets/dialogs/replace_cloud_backup_dialog.dart';
import 'package:provider/provider.dart';

/// Shown on sign-in (Google Drive or iCloud) when the cloud already has a
/// backup and this device has data: merge both, replace local data with the
/// backup, or ignore the backup and upload this device's data instead.
class RestoreChoiceDialog extends StatelessWidget {
  const RestoreChoiceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bp = context.read<BackupProvider>();
    final isICloud = bp.restoreDecisionIsICloud;

    return NewDefaultDialog(
      title: loc.backupFound,
      desc: isICloud ? loc.backupFoundDescICloud : loc.backupFoundDesc,
      overrideDefaultButtons: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          // ─── Merge ────────────────────────────────────────────
          NewDefaultButton.primary(
            label: loc.merge,
            onPressed: () {
              bp.confirmMerge();
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
          // ─── Replace local data with the backup ───────────────
          NewDefaultButton.secondary(
            label: loc.delete,
            onPressed: () {
              showDialogSheet<void>(
                context: context,
                builder:
                    (_) => OverwriteLocalDataDialog(
                      onConfirmed: () {
                        bp.confirmReplace();
                        if (context.mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
              );
            },
          ),
          // ─── Ignore the backup and upload mine ────────────────
          NewDefaultButton.secondary(
            label: loc.ignoreBackupUploadMine,
            onPressed: () {
              showDialogSheet<void>(
                context: context,
                builder:
                    (_) => ReplaceCloudBackupDialog(
                      cloudName: isICloud ? 'iCloud' : 'Google Drive',
                      onConfirmed: () {
                        bp.confirmUploadMine();
                        if (context.mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
