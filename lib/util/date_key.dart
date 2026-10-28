/// Date-only key (`yyyy-MM-dd`), matching the insight flow's format. Used for
/// once-per-day gates, which compare calendar days rather than 24 h spans so
/// DST shifts cannot move a boundary.
String dateKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.toIso8601String().split('T').first;
}
