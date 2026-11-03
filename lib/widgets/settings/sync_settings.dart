import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/settings/health_device_setting.dart';
import 'package:habitt/widgets/settings/sync_speed_setting.dart';
import 'package:provider/provider.dart';

/// Settings section shown once a cloud backup (Google Drive or iCloud) is
/// connected.
class SyncSettings extends StatelessWidget {
  const SyncSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isLoggedIn = context.select<BackupProvider, bool>(
      (bp) => bp.isLoggedIn,
    );
    final loc = AppLocalizations.of(context)!;

    if (!isLoggedIn) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          loc.syncSectionTitle,
          style: TextStyle(color: cp.lightGreyText, fontSize: 16),
        ),
        const SyncSpeedSetting(),
        const HealthDeviceSetting(),
      ],
    );
  }
}
