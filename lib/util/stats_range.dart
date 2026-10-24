/// Time window the habit details stats can be switched between.
enum StatsRange {
  week(7),
  month(30),
  all(null);

  const StatsRange(this.days);

  /// Length of the window in days, null for the whole history.
  final int? days;

  /// First day of the window ending on [today], null when it has no start.
  DateTime? startFor(DateTime today) {
    final length = days;
    if (length == null) return null;
    return DateTime(today.year, today.month, today.day - (length - 1));
  }
}
