/// Category a habit scheduled at [minutes] (since midnight) belongs to, using
/// the same day periods as the "Now" badge and category reordering:
/// Morning 04:00–12:00, Afternoon 12:00–19:00, Evening 19:00–04:00.
int categoryIdForMinutes(int minutes) {
  final hour = (minutes % (24 * 60)) ~/ 60;
  if (hour >= 4 && hour < 12) return 2; // Morning
  if (hour >= 12 && hour < 19) return 3; // Afternoon
  return 4; // Evening
}
