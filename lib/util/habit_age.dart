/// How long a habit has existed, as whole calendar units.
class HabitAge {
  const HabitAge({required this.years, required this.months, required this.days});

  final int years;
  final int months;

  /// Total days between the start and today, not the remainder.
  final int days;

  bool get isNew => days < 1;
}

HabitAge habitAge(DateTime createdAt, DateTime today) {
  final start = DateTime(createdAt.year, createdAt.month, createdAt.day);
  final end = DateTime(today.year, today.month, today.day);
  if (!end.isAfter(start)) {
    return const HabitAge(years: 0, months: 0, days: 0);
  }

  var totalMonths = (end.year - start.year) * 12 + end.month - start.month;
  if (end.day < start.day) totalMonths -= 1;

  return HabitAge(
    years: totalMonths ~/ 12,
    months: totalMonths % 12,
    // utc so a daylight-saving change can't shave an hour off a day
    days:
        DateTime.utc(end.year, end.month, end.day)
            .difference(DateTime.utc(start.year, start.month, start.day))
            .inDays,
  );
}
