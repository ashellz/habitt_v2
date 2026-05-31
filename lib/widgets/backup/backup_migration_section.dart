import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

class BackupMigrationSection extends StatefulWidget {
  const BackupMigrationSection({super.key});

  @override
  State<BackupMigrationSection> createState() => _BackupMigrationSectionState();
}

class _BackupMigrationSectionState extends State<BackupMigrationSection> {
  final _passphraseController = TextEditingController();
  bool _migrationLoading = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _handleMigrate(BackupProvider bp) async {
    final passphrase = _passphraseController.text.trim();
    if (passphrase.isEmpty) return;

    setState(() => _migrationLoading = true);
    final success = await bp.migrateFromLegacy(passphrase);
    if (mounted) {
      setState(() => _migrationLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bp.lastError ?? AppLocalizations.of(context)!.migrationFailed,
            ),
          ),
        );
      } else {
        _passphraseController.clear();
      }
    }
  }

  Future<void> _confirmDiscardLegacy(
    BackupProvider bp,
    AppLocalizations loc,
  ) async {
    final cp = context.read<ColorProvider>();
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => NewDefaultDialog(
            title: loc.discardOldBackupTitle,
            desc: loc.discardOldBackupDesc,
            primaryButtonLabel: loc.discardOldBackupConfirm,
            primaryButtonColor: cp.error,
            onPrimaryButtonPressed: () => Navigator.of(ctx).pop(true),
            secondaryButtonLabel: loc.cancel,
            onSecondaryButtonPressed: () => Navigator.of(ctx).pop(false),
          ),
    );
    if (confirmed == true && context.mounted) {
      await bp.discardLegacyBackup();
    }
  }

  Future<void> _confirmSignOut(
    BackupProvider bp,
    AppLocalizations loc,
  ) async {
    final cp = context.read<ColorProvider>();
    final confirmed = await showDialogSheet<bool>(
      context: context,
      builder:
          (ctx) => NewDefaultDialog(
            title: loc.logOut,
            desc: loc.logOutDesc,
            primaryButtonLabel: loc.logOut,
            primaryButtonColor: cp.error,
            onPrimaryButtonPressed: () => Navigator.of(ctx).pop(true),
            secondaryButtonLabel: loc.cancel,
            onSecondaryButtonPressed: () => Navigator.of(ctx).pop(false),
          ),
    );
    if (confirmed == true && mounted) {
      await bp.signOut();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bp = context.watch<BackupProvider>();
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: cp.field,
              shape: RoundedRectangleBorder(
                side: BorderSide(width: 1, color: cp.border),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.migrateToSeamlessSync,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.legacyBackupDescription,
                  style: TextStyle(
                    color: cp.greyText,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                NewDefaultTextField(
                  controller: _passphraseController,
                  obscureText: true,
                  color: cp.habitBg,
                ),
                const SizedBox(height: 16),
                NewDefaultButton.primary(
                  width: double.infinity,
                  onPressed: () => _handleMigrate(bp),
                  label: loc.migrate,
                  isLoading: _migrationLoading,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => _confirmDiscardLegacy(bp, loc),
              child: Text(
                loc.forgotPassphrase,
                style: TextStyle(
                  color: cp.greyText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () => _confirmSignOut(bp, loc),
              child: Text(
                loc.disconnectGoogle,
                style: TextStyle(
                  color: cp.error,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
