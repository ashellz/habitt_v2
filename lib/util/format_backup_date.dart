import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/date_key.dart';

/// "Today at 19:05", "Yesterday at 19:05" or "Nov 3 at 19:05", used for the
/// last sync time and the date of a backup found in the cloud.
String formatBackupDate(DateTime date, AppLocalizations loc) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = addCalendarDays(today, -1);
  final day = DateTime(date.year, date.month, date.day);

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final time = '$hour:$minute';

  if (day == today) return loc.backupDateToday(time);
  if (day == yesterday) return loc.backupDateYesterday(time);

  final months = [
    loc.monthJan,
    loc.monthFeb,
    loc.monthMar,
    loc.monthApr,
    loc.monthMay,
    loc.monthJun,
    loc.monthJul,
    loc.monthAug,
    loc.monthSep,
    loc.monthOct,
    loc.monthNov,
    loc.monthDec,
  ];
  return loc.backupDateOther(months[date.month - 1], '${date.day}', time);
}
