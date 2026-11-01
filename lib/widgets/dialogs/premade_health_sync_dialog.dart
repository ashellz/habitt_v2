import 'dart:io';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/util/health_source_name.dart';
import 'package:habitt/util/premade_health_sync.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/whats_new/whats_new_graphic_frame.dart';
import 'package:habitt/widgets/whats_new/whats_new_health_graphic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

/// Asks whether a premade habit should sync with Apple Health / Health Connect.
/// Pops `true` for "Use …", `false` for "Track manually".
class PremadeHealthSyncDialog extends StatelessWidget {
  const PremadeHealthSyncDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.watch<ColorProvider>();
    final source = healthSourceName();

    return NewDefaultDialog(
      title: loc.premadeHealthSyncTitle(source),
      primaryButtonLabel: loc.premadeHealthSyncAccept(source),
      secondaryButtonLabel: loc.premadeHealthSyncDecline,
      onPrimaryButtonPressed: () => Navigator.of(context).pop(true),
      onSecondaryButtonPressed: () => Navigator.of(context).pop(false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          // same graphic and frame as the 2.5.0 What's new dialog
          const SizedBox(
            height: WhatsNewGraphicFrame.height,
            child: WhatsNewHealthGraphic(),
          ),
          Text(
            loc.premadeHealthSyncDesc(source),
            style: TextStyle(color: cp.greyText, fontSize: 16, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// Runs before a premade habit's sheet opens (and before any OS prompt).
/// Returns whether Health sync should be on for the habit. A template without
/// a Health metric returns `true` (nothing to turn off).
Future<bool> askPremadeHealthSync(
  BuildContext context,
  PremadeHabitTemplate template,
) async {
  if (template.defaultHealthMetric == null) return true;

  final health = context.read<HealthProvider>();
  await health.ensureAvailabilityChecked();
  final accepted = await loadPremadeHealthSyncAccepted();
  if (!context.mounted) return false;

  final decision = decidePremadeHealthPrompt(
    template: template,
    isAvailable: health.isAvailable,
    isMetricSupported: health.isMetricSupported(template.defaultHealthMetric!),
    permissionGranted: health.permissionGranted,
    previouslyAccepted: accepted,
  );

  switch (decision) {
    case PremadeHealthDecision.notHealthLinked:
    case PremadeHealthDecision.syncWithoutAsking:
      return true;
    case PremadeHealthDecision.manualOnly:
      return false;
    case PremadeHealthDecision.ask:
      // not dismissible: leaving by tapping outside would be an ambiguous answer
      final result = await showDialogSheet<bool>(
        context: context,
        dismissible: false,
        builder: (_) => const PremadeHealthSyncDialog(),
      );
      if (result == true) await savePremadeHealthSyncAccepted();
      return result ?? false;
  }
}

/// Requests the OS permission after the user accepted. When it is denied,
/// [onDenied] reverts the habit to manual tracking, silently: the user just
/// refused in the OS prompt. Turning sync on again later asks again and, if
/// that fails too, shows [showHealthPermissionDeniedDialog]. Returns whether
/// access was granted. (iOS never reports a refusal, only Android does.)
Future<bool> requestHealthAccessOrRevert(
  BuildContext context, {
  required VoidCallback onDenied,
}) async {
  final granted =
      await context.read<HealthProvider>().requestPermissionIfNeeded();
  if (!granted) onDenied();
  return granted;
}

Future<void> showHealthPermissionDeniedDialog(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  await showDialogSheet(
    context: context,
    builder:
        (dialogContext) => NewDefaultDialog(
          title:
              Platform.isIOS
                  ? loc.healthSyncSectionTitleApple
                  : loc.healthSyncSectionTitleAndroid,
          desc: loc.healthPermissionDeniedMessage,
          primaryButtonLabel: loc.healthOpenSettings,
          secondaryButtonLabel: loc.cancel,
          onPrimaryButtonPressed: () {
            Navigator.of(dialogContext).pop();
            openAppSettings();
          },
          onSecondaryButtonPressed: () => Navigator.of(dialogContext).pop(),
        ),
  );
}
