import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/get_capitalized_first.dart';
import 'package:intl/intl.dart';

/// Short label for the day a habit is next scheduled on, shared by the habits
/// page tag and the habit details "scheduled for" widget: "Today",
/// "Tomorrow", the weekday within the next week ("Tuesday"), then the date
/// ("12th Oct"), with the year added once it is not this year ("2nd Jan 2027").
/// Weekday and month names follow [locale].
String nextScheduledLabel(
  AppLocalizations loc,
  Locale locale,
  DateTime date, {
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  final days = calendarDaysBetween(now, date);
  final tag = locale.toString();

  if (days <= 0) return loc.today;
  if (days == 1) return loc.tomorrow;
  if (days < 7) return capitalizeFirst(DateFormat.EEEE(tag).format(date));

  final day = date.day.toString();
  final suffix = _ordinalSuffix(locale.languageCode, date.day);
  final month = DateFormat.MMM(tag).format(date);
  if (date.year == now.year) {
    return loc.dayMonthLabel(day, suffix, month);
  }
  return loc.dayMonthYearLabel(day, suffix, month, date.year.toString());
}

/// Whole calendar days from [from] to [to] (negative when [to] is earlier),
/// counted on dates alone so a DST shift can't move the result.
int calendarDaysBetween(DateTime from, DateTime to) {
  return DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}

// Only English writes days as ordinals ("12th"); the other languages show the
// bare number.
String _ordinalSuffix(String languageCode, int day) {
  if (languageCode != 'en') return '';
  if (day >= 11 && day <= 13) return 'th';
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
