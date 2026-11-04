import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/blur_fade.dart';
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

    // The account is usually restored before this page is opened, but if it
    // lands later (e.g. iCloud availability check) the section blur fades in
    // like the streak calendar, while its height eases open instead of
    // pushing the content below it down in one jump.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder:
          (child, animation) => SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: BlurFade.transition(child, animation),
          ),
      child:
          !isLoggedIn
              ? const SizedBox(key: ValueKey(false), width: double.infinity)
              : Column(
                key: const ValueKey(true),
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
              ),
    );
  }
}
