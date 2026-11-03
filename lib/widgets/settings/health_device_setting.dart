import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/sync_device.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/providers/sync_devices_provider.dart';
import 'package:habitt/widgets/settings/health_device_option.dart';
import 'package:provider/provider.dart';

/// Which device reads Health when several phones share one Google Drive
/// backup. Shown on every one of them; the others only receive its values.
class HealthDeviceSetting extends StatelessWidget {
  const HealthDeviceSetting({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) {
      return const SizedBox.shrink();
    }

    final devices = context.watch<SyncDevicesProvider>();
    if (!devices.isMultiDevice) return const SizedBox.shrink();

    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final source = devices.healthSource;

    // an Android source can't fill these, worth saying only if they're in use
    final showIosOnlyNote =
        source != null &&
        !source.isIos &&
        context.select<HabitProvider, bool>(
          (hp) => hp.habits.any(
            (h) => h.isDeleted != true && h.healthMetric?.isIosOnly == true,
          ),
        );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: cp.isDark ? cp.habitBg : cp.bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: cp.border),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(
            loc.healthDeviceTitle,
            style: TextStyle(color: cp.lightGreyText, fontSize: 16),
          ),
          Column(
            spacing: 8,
            children: [
              for (final device in devices.devices)
                HealthDeviceOption(
                  device: device,
                  isSelected: device.id == source?.id,
                  isThisDevice: device.id == devices.selfId,
                  onTap: () => _pick(context, device),
                ),
            ],
          ),
          if (showIosOnlyNote)
            Text(
              loc.healthDeviceIosOnlyNote,
              style: TextStyle(color: cp.lightGreyText, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context, SyncDevice device) async {
    final devices = context.read<SyncDevicesProvider>();
    if (device.id == devices.healthSource?.id) return;
    final backup = context.read<BackupProvider>();
    final health = context.read<HealthProvider>();

    await devices.setHealthSource(device.id);
    // the other devices only learn the pick from the next upload
    backup.scheduleAutoSync();

    // this device reads Health from now on: ask for access the first time,
    // then pull today in right away instead of on the next app open
    if (device.id == devices.selfId &&
        await health.requestPermissionIfNeeded()) {
      await health.syncNow();
    }
  }
}
