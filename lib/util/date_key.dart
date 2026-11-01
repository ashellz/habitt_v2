/// Date-only key (`yyyy-MM-dd`), matching the insight flow's format. Used for
/// once-per-day gates, which compare calendar days rather than 24 h spans so
/// DST shifts cannot move a boundary.
String dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.toIso8601String().split('T').first;
}

/// [date]'s calendar day moved by [days], at local midnight.
///
/// Use this instead of `date.add(Duration(days: n))` for calendar dates: a
/// Duration day is always 24 h, so across a 25 h DST fall-back day it lands on
/// 23:00 of the day before (and across a 23 h spring-forward day on 01:00, or
/// 23:00 two days back when subtracting), which shifts the date.
DateTime addCalendarDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

/// Whole calendar days from [from] to [to], ignoring time of day and DST
/// (negative when [to] is before [from]).
int calendarDaysBetween(DateTime from, DateTime to) {
  return DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
