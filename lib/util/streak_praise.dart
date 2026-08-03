import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/streak_health.dart';

List<String> streakPraiseOptions(AppLocalizations l) {
  return [
    l.youreDoingGreat,
    l.goodJob,
    l.bravo,
    l.keepItUp,
    l.youreALegend,
    l.keepGoing,
    l.streakInventYou,
    l.streakPraiseExtra1,
    l.streakPraiseExtra2,
    l.streakPraiseExtra3,
  ];
}

List<String> streakFadingOptions(AppLocalizations l) {
  return [l.streakFadingNudge1, l.streakFadingNudge2, l.streakFadingNudge3];
}

// partial means that all habits are at least partially completed for the day, but not all are fully completed
List<String> streakFadingPartialOptions(AppLocalizations l) {
  return [l.streakFadingPartial1, l.streakFadingPartial2];
}

List<String> streakCriticalOptions(AppLocalizations l) {
  return [l.streakCriticalWarning1, l.streakCriticalWarning2];
}

List<String> streakCriticalPartialOptions(AppLocalizations l) {
  return [l.streakCriticalPartial1, l.streakCriticalPartial2];
}

List<String> streakCopyOptions(
  AppLocalizations l, {
  required StreakHealth health,
  required bool hasProgressToday,
}) {
  return switch (health) {
    StreakHealth.healthy || StreakHealth.dormant => streakPraiseOptions(l),
    StreakHealth.fading =>
      hasProgressToday ? streakFadingPartialOptions(l) : streakFadingOptions(l),
    StreakHealth.critical =>
      hasProgressToday
          ? streakCriticalPartialOptions(l)
          : streakCriticalOptions(l),
  };
}
