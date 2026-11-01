// How far back a Health sync run goes to catch up on days the app wasn't
// opened on. Pure date math, no I/O, so it is easy to test.

/// The most days a catch-up goes back from the day being synced. Health
/// Connect only lets an app read the 30 days before its first permission grant
/// (`READ_HEALTH_DATA_HISTORY` lifts that, but it is a separate permission), so
/// this stays well inside that window.
const int kHealthBackfillMaxDays = 14;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The earliest day a habit may be synced on: never before it was created, and
/// never before it was last paused or unpaused. Paused habits don't appear on
/// past days, and unpausing must not re-add the paused stretch.
DateTime healthBackfillFloor({
  required DateTime createdAt,
  DateTime? pauseChangedAt,
}) {
  var floor = _dateOnly(createdAt.toLocal());
  if (pauseChangedAt != null) {
    final pausedDay = _dateOnly(pauseChangedAt.toLocal());
    if (pausedDay.isAfter(floor)) floor = pausedDay;
  }
  return floor;
}

/// The days a sync run reads for one habit: [syncDay] first (what the user is
/// looking at), then the earlier days to catch up on, oldest to newest.
///
/// [cursor] is the last day this habit was synced up to. It is read again, so a
/// night a watch uploads late settles on the next open. With no cursor (a habit
/// that was just linked) only [syncDay] is read, so a habit never backfills
/// before it was linked. The range is cut to [maxDays] before [syncDay] and
/// never goes before [floor].
List<DateTime> healthCatchUpDays({
  required DateTime syncDay,
  DateTime? cursor,
  DateTime? floor,
  int maxDays = kHealthBackfillMaxDays,
}) {
  final end = _dateOnly(syncDay);
  final days = <DateTime>[end];
  if (cursor == null) return days;

  var start = _dateOnly(cursor);
  // a cursor on or after syncDay (e.g. bedtime was switched to "day before")
  // has nothing earlier to catch up on
  if (!start.isBefore(end)) return days;

  final cap = DateTime(end.year, end.month, end.day - maxDays);
  if (start.isBefore(cap)) start = cap;
  if (floor != null && start.isBefore(_dateOnly(floor))) {
    start = _dateOnly(floor);
  }

  for (
    var d = start;
    d.isBefore(end);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    days.add(d);
  }
  return days;
}
