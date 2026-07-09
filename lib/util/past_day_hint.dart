bool isPastDayHintEligible({
  required DateTime dateJoined,
  required bool hasSelectedPastDay,
}) {
  if (hasSelectedPastDay) return false;
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final yesterday = normalizedToday.subtract(const Duration(days: 1));
  final normalizedJoined = DateTime(
    dateJoined.year,
    dateJoined.month,
    dateJoined.day,
  );
  return !yesterday.isBefore(normalizedJoined);
}
