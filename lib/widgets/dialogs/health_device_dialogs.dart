import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/sync_device.dart';
import 'package:habitt/util/health_source_name.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';

/// Asked before unlinking a metric this phone can't read (linked on an
/// iPhone): it can't be picked again here. True when the user confirms.
Future<bool> confirmUnlinkForeignHealthMetric(
  BuildContext context,
  HealthMetricType metric,
) async {
  final loc = AppLocalizations.of(context)!;
  final confirmed = await showDialogSheet<bool>(
    context: context,
    builder:
        (dialogContext) => NewDefaultDialog(
          title: loc.healthForeignMetricOffTitle,
          desc: loc.healthForeignMetricOffDesc(metric.label(loc)),
          primaryButtonLabel: loc.healthForeignMetricOffConfirm,
          secondaryButtonLabel: loc.cancel,
          onPrimaryButtonPressed: () => Navigator.of(dialogContext).pop(true),
          onSecondaryButtonPressed:
              () => Navigator.of(dialogContext).pop(false),
        ),
  );
  return confirmed == true;
}

/// Why a phone in the "Health sync from" picker can't be the reader.
Future<void> showHealthDeviceUnavailableInfo(
  BuildContext context,
  SyncDevice device,
) {
  final loc = AppLocalizations.of(context)!;
  return showDialogSheet(
    context: context,
    builder:
        (_) => NewDefaultDialog(
          title: device.displayName,
          desc: loc.healthDeviceUnavailableInfo(
            healthSourceNameFor(device.platform),
          ),
          showSecondaryButton: false,
          primaryButtonLabel: loc.gotIt,
        ),
  );
}

/// An Android phone was tapped while an Activity or Mindfulness habit exists:
/// those habits stop syncing on it. True when the user switches anyway.
Future<bool> confirmAndroidHealthSource(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  final confirmed = await showDialogSheet<bool>(
    context: context,
    builder:
        (dialogContext) => NewDefaultDialog(
          desc: loc.healthDeviceIosOnlyBlocked,
          primaryButtonLabel: loc.healthDeviceSwitchAnyway,
          secondaryButtonLabel: loc.cancel,
          onPrimaryButtonPressed: () => Navigator.of(dialogContext).pop(true),
          onSecondaryButtonPressed:
              () => Navigator.of(dialogContext).pop(false),
        ),
  );
  return confirmed == true;
}
