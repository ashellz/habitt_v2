import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/dialogs/restore_choice_dialog.dart';
import 'package:habitt/widgets/profile/profile_options.dart';
import 'package:habitt/widgets/sheets/local_backup_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class BackupSignedOutSection extends StatefulWidget {
  const BackupSignedOutSection({super.key, required this.onAfterSignIn});

  final VoidCallback onAfterSignIn;

  @override
  State<BackupSignedOutSection> createState() => _BackupSignedOutSectionState();
}

class _BackupSignedOutSectionState extends State<BackupSignedOutSection> {
  bool _signingIn = false;
  bool _connectingICloud = false;

  Future<void> _handleSignIn(BackupProvider bp) async {
    setState(() => _signingIn = true);
    await bp.signIn(context);
    if (mounted) setState(() => _signingIn = false);
    if (!mounted) return;
    if (context.read<BackupProvider>().pendingRestoreDecision) {
      await showDialogSheet<void>(
        context: context,
        builder: (_) => const RestoreChoiceDialog(),
      );
    }
    if (!mounted) return;
    widget.onAfterSignIn();
  }

  Future<void> _handleConnectICloud(BackupProvider bp) async {
    if (_connectingICloud) return;
    setState(() => _connectingICloud = true);
    await bp.activateICloud();
    if (mounted) setState(() => _connectingICloud = false);
    if (!mounted) return;
    widget.onAfterSignIn();
  }

  void _showLocalBackupSheet() {
    final cp = context.read<ColorProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
      barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (context) => const LocalBackupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bp = context.watch<BackupProvider>();
    final loc = AppLocalizations.of(context)!;
    final showICloud = !kIsWeb && Platform.isIOS;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShapeDecoration(
          color: cp.habitBg,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: cp.border),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // ─── Local Backups ─────────────────────────────────────────────
            ProfileOption(
              cp: cp,
              text: loc.localBackups,
              svgPath: 'assets/images/new-svg/local-backup.svg',
              onTap: _showLocalBackupSheet,
            ),
            Divider(color: cp.border, height: 0),
            // ─── Google Drive ──────────────────────────────────────────────
            GestureDetector(
              onTap: _signingIn ? null : () => _handleSignIn(bp),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.transparent,
                child: Row(
                  spacing: 12,
                  children: [
                    Text(
                      loc.connectGoogleDrive,
                      style: TextStyle(
                        color: cp.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_signingIn)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cp.text,
                        ),
                      )
                    else
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: SvgPicture.asset(
                          'assets/images/new-svg/google.svg',
                          colorFilter: ColorFilter.mode(
                            cp.lightGreyText,
                            BlendMode.srcIn,
                          ),
                          fit: BoxFit.contain,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ─── iCloud (iOS only) ─────────────────────────────────────────
            if (showICloud) ...[
              Divider(color: cp.border, height: 0),
              GestureDetector(
                onTap:
                    _connectingICloud ? null : () => _handleConnectICloud(bp),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.transparent,
                  child: Row(
                    spacing: 12,
                    children: [
                      Text(
                        loc.connectICloud,
                        style: TextStyle(
                          color: cp.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (_connectingICloud)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cp.text,
                          ),
                        )
                      else
                        Icon(Icons.apple, color: cp.lightGreyText, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
