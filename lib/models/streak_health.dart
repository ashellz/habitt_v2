enum StreakHealth { healthy, fading, critical, dormant }

StreakHealth resolveStreakHealth({
  required int streak,
  required int tailMisses,
  required bool todayIsSecure,
}) {
  if (streak <= 0) return StreakHealth.dormant;
  if (tailMisses <= 0 || todayIsSecure) return StreakHealth.healthy;
  return tailMisses == 1 ? StreakHealth.fading : StreakHealth.critical;
}
