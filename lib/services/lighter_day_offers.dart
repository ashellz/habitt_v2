import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/services/goal_check_in_analyzer.dart';
import 'package:habitt/services/lighter_day_policy.dart';

/// Builds today's lighter-day offers from the live providers, for the in-app
/// sheet and the evening notification. See docs/goal_check_in.md.
class LighterDayOffers {
  const LighterDayOffers._();

  /// The evening check-in time, 20:25 local: off the hour so it doesn't land
  /// together with other apps' 20:00 notifications.
  static const int eveningHour = 20;
  static const int eveningMinute = 25;

  static DateTime eveningOf(DateTime day) =>
      DateTime(day.year, day.month, day.day, eveningHour, eveningMinute);

  static bool isEvening(DateTime now) => !now.isBefore(eveningOf(now));

  /// Every habit due today that qualifies for an offer.
  static List<LighterDayOffer> forToday(HabitProvider hp, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final stats = hp.statsProvider;
    final days = hp.daysBox.values.toList();
    final offers = <LighterDayOffer>[];
    for (var i = 0; i < hp.todaysHabits.length; i++) {
      final habit = hp.todaysHabits[i];
      if (habit.isDeleted == true) continue;
      final offer = LighterDayPolicy.evaluate(
        LighterDayInput(
          habit: habit,
          scheduledToday: true,
          recent: GoalCheckInAnalyzer.collect(
            days: days,
            habitId: habit.id,
            today: today,
            isInactiveOnDay: (d) => hp.inactiveOnPastDay(habit.id, d),
          ),
          lighterDaysThisWeek: LighterDayPolicy.lighterDaysThisWeek(
            days: days,
            habitId: habit.id,
            today: today,
          ),
          habitMisses: hp.consecutiveMissesFor(habit.id),
          perfectStreak: stats?.perfectDaysStreak ?? 0,
          perfectTailMisses: stats?.perfectDaysTailMisses ?? 0,
          order: i,
        ),
      );
      if (offer != null) offers.add(offer);
    }
    return offers;
  }

  /// The offer to show or notify about, skipping habits [skip] returns true
  /// for (already shown today).
  static LighterDayOffer? best(
    HabitProvider hp, {
    DateTime? now,
    bool Function(int habitId)? skip,
  }) => LighterDayPolicy.pick(
    forToday(hp, now: now).where((o) => !(skip?.call(o.habit.id) ?? false)),
  );
}
