import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/health_provider.dart';
import 'package:habitt/providers/sync_devices_provider.dart';
import 'package:habitt/util/health_restore_check.dart';
import 'package:habitt/util/health_source_name.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/health_connect_icon.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/health_restore_habit_groups.dart';
import 'package:habitt/widgets/dialogs/premade_health_sync_dialog.dart';
import 'package:provider/provider.dart';

/// After a backup is restored, while no device syncs Health yet: compares the
/// Health habits with what this phone can read. Offers to sync them from this
/// phone when it can read them (all, or some, showing which ones will sync),
/// or says they won't update here when it can read none. Never unlinks a
/// habit or touches its history.
Future<void> showHealthRestoreNotice(BuildContext context) async {
  final health = context.read<HealthProvider>();
  final devices = context.read<SyncDevicesProvider>();
  final habits = context.read<HabitProvider>().habits;

  final isPhone = !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  if (isPhone) await health.ensureAvailabilityChecked();
  await devices.ensureLoaded();
  if (!context.mounted) return;

  // another device reads Health (e.g. an iPhone for Apple Health): its
  // values reach this phone through sync, so there is nothing to offer or
  // warn about here; switching is up to the picker in settings
  final source = devices.healthSource;
  if (source != null && source.id != devices.selfId) return;

  // this phone already syncs Health (e.g. its own local file restored)
  if (health.lastSyncedAt != null) return;

  final check = checkRestoredHealthHabits(
    habits,
    canRead:
        (metric) =>
            isPhone && health.isAvailable && health.isMetricSupported(metric),
  );
  if (!check.hasHealthHabits) return;

  if (check.trackable.isEmpty) return showHealthRestoreNoneDialog(context);

  final accepted = await showHealthRestoreOfferDialog(
    context,
    trackable: check.trackable,
    untrackable: check.untrackable,
  );
  if (!accepted || !context.mounted) return;
  await _syncHealthFromThisPhone(context);
}

// this phone's Health store, for the dialog's title icon
Widget _sourceLogo() =>
    healthSourceName() == 'Apple Health'
        ? SvgPicture.asset('assets/images/widget-images/apple-health.svg')
        : const HealthConnectIcon(size: 28);

/// Restored Health habits this phone can read none of.
Future<void> showHealthRestoreNoneDialog(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  return showDialogSheet(
    context: context,
    builder:
        (_) => NewDefaultDialog(
          titleIcon: _sourceLogo(),
          title: loc.healthSourceUnavailableTitle(healthSourceName()),
          desc: loc.healthRestoreNoneDesc,
          showSecondaryButton: false,
          primaryButtonLabel: loc.gotIt,
        ),
  );
}

/// "Sync Health habits from this phone?". When some habits are Apple Health
/// exclusive (restored onto Android), it lists which ones will sync and
/// which won't instead of the general text. True when the user accepts.
Future<bool> showHealthRestoreOfferDialog(
  BuildContext context, {
  List<Habit> trackable = const [],
  List<Habit> untrackable = const [],
}) async {
  final loc = AppLocalizations.of(context)!;
  final partial = untrackable.isNotEmpty;
  final accepted = await showDialogSheet<bool>(
    context: context,
    builder:
        (dialogContext) => NewDefaultDialog(
          titleIcon: _sourceLogo(),
          title: loc.healthRestoreOfferTitle,
          desc: partial ? null : loc.healthRestoreOfferDesc(healthSourceName()),
          primaryButtonLabel: loc.healthRestoreSyncHere,
          secondaryButtonLabel: partial ? loc.cancel : loc.notNow,
          onPrimaryButtonPressed: () => Navigator.of(dialogContext).pop(true),
          onSecondaryButtonPressed:
              () => Navigator.of(dialogContext).pop(false),
          child:
              partial
                  ? HealthRestoreHabitGroups(
                    trackable: trackable,
                    untrackable: untrackable,
                  )
                  : null,
        ),
  );
  return accepted == true;
}

Future<void> _syncHealthFromThisPhone(BuildContext context) async {
  final health = context.read<HealthProvider>();
  final devices = context.read<SyncDevicesProvider>();
  final backup = context.read<BackupProvider>();

  // pick this phone whenever another one is listed, even before this phone
  // lists itself: it would otherwise lose the default to an older install
  final selfId = devices.selfId;
  if (selfId != null && devices.devices.any((d) => d.id != selfId)) {
    // list this phone first, a pick of an unlisted device doesn't count yet
    await devices.listForUpload();
    await devices.setHealthSource(selfId);
    // the other devices only learn the pick from the next upload
    backup.scheduleAutoSync();
  }

  if (!await health.requestPermissionIfNeeded()) {
    if (context.mounted) await showHealthPermissionDeniedDialog(context);
    return;
  }
  // the normal catch-up window (kHealthBackfillMaxDays), not only today
  await health.syncNowWithCatchUp();
}
