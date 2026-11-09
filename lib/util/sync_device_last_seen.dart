import 'package:flutter/widgets.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/sync_device.dart';
import 'package:intl/intl.dart';

/// When [device] last synced, as a day: "Today" or "2 Nov". A device
/// refreshes its entry about once a day, so a day is all that's worth showing.
String syncDeviceLastSeenLabel(
  BuildContext context,
  AppLocalizations loc,
  SyncDevice device,
) {
  final seen = device.lastSeen.toLocal();
  final now = DateTime.now();
  if (seen.year == now.year && seen.month == now.month && seen.day == now.day) {
    return loc.today;
  }
  return DateFormat(
    'd MMM',
    Localizations.localeOf(context).toString(),
  ).format(seen);
}
