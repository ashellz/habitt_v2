import 'package:habitt/util/health_history.dart';

/// Whether to hint that Habitt may lack Health access.
///
/// iOS never says whether read access was granted, so a declined prompt looks
/// like a granted one that returns nothing. The best signal is a linked habit
/// that has shown no data for the last [days] days: every one of those days
/// has no value or 0. Habits younger than [days] days are never flagged, since
/// they simply haven't had time to collect anything.
bool shouldHintHealthAccess({
  required HealthHistory history,
  required DateTime createdAt,
  required DateTime today,
  int days = 3,
}) {
  final todayStart = DateTime(today.year, today.month, today.day);
  final createdStart = DateTime(createdAt.year, createdAt.month, createdAt.day);
  if (todayStart.difference(createdStart).inDays < days) return false;
  if (history.points.length < days) return false;

  final recent = history.points.sublist(history.points.length - days);
  return recent.every((p) => p.value == null || p.value == 0);
}
