import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class ThinSyncIndicator extends StatelessWidget {
  const ThinSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BackupProvider>();
    final visible = bp.syncState == SyncState.syncing && bp.syncPillDismissed;
    final cp = context.watch<ColorProvider>();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: visible ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -6.0 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: LinearProgressIndicator(
        value: bp.syncIsUploading ? null : bp.syncProgress,
        semanticsLabel: AppLocalizations.of(context)!.syncOverlayTitleSyncing,
        minHeight: 3,
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(cp.main),
      ),
    );
  }
}
