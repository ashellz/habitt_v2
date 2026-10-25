/// The encouragement shown for a habit of a given age.
enum HabitAgeMilestone {
  startedToday,
  starting,
  rhythm,
  routine,
  impressive,
  outstanding,
  dedication,
  legendary,
}

/// How long a habit has existed, as whole calendar units.
class HabitAge {
  const HabitAge({
    required this.years,
    required this.months,
    required this.days,
    this.extraDays = 0,
  });

  final int years;
  final int months;

  /// Total days between the start and today, not the remainder.
  final int days;

  /// Days left over after [years] and [months] are taken off.
  final int extraDays;

  bool get isNew => days < 1;

  HabitAgeMilestone get milestone {
    if (days < 1) return HabitAgeMilestone.startedToday;
    if (days < 7) return HabitAgeMilestone.starting;
    if (days < 30) return HabitAgeMilestone.rhythm;
    if (days < 90) return HabitAgeMilestone.routine;
    if (days < 180) return HabitAgeMilestone.impressive;
    if (days < 365) return HabitAgeMilestone.outstanding;
    if (days < 730) return HabitAgeMilestone.dedication;
    return HabitAgeMilestone.legendary;
  }
}

HabitAge habitAge(DateTime createdAt, DateTime today) {
  final start = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final end = DateTime(today.year, today.month, today.day);
  if (!end.isAfter(start)) {
    return const HabitAge(years: 0, months: 0, days: 0);
  }

  var totalMonths = (end.year - start.year) * 12 + end.month - start.month;
  if (end.day < start.day) totalMonths -= 1;

  // the last whole month, with the day clamped so Jan 31 + 1 month is Feb 28
  final anchorMonth = start.month + totalMonths;
  final daysInAnchorMonth = DateTime(start.year, anchorMonth + 1, 0).day;
  final anchor = DateTime(
    start.year,
    anchorMonth,
    start.day > daysInAnchorMonth ? daysInAnchorMonth : start.day,
  );

  return HabitAge(
    years: totalMonths ~/ 12,
    months: totalMonths % 12,
    days: _daysBetween(start, end),
    extraDays: _daysBetween(anchor, end),
  );
}

// utc so a daylight-saving change can't shave an hour off a day
int _daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(
      to.year,
      to.month,
      to.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
