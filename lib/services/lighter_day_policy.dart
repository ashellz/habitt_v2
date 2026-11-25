import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/stats_provider.dart' show kStreakMissTolerance;
import 'package:habitt/services/goal_check_in_analyzer.dart';
import 'package:habitt/util/date_key.dart';

/// What the evening offer asks.
enum LighterDayKind {
  /// Pick a goal for today only from [LighterDayOffer.values].
  lighter,

  /// The streak ends tonight but this week's lighter days are used up: log
  /// any amount (a partial day is neutral) instead.
  saveStreak,
}

/// Everything [LighterDayPolicy.evaluate] needs about one habit today.
class LighterDayInput {
  const LighterDayInput({
    required this.habit,
    required this.scheduledToday,
    required this.recent,
    required this.lighterDaysThisWeek,
    required this.habitMisses,
    this.perfectStreak = 0,
    this.perfectTailMisses = 0,
    this.order = 0,
  });

  /// The live habit, today's state.
  final Habit habit;
  final bool scheduledToday;

  /// Concluded days before today, oldest first
  /// ([GoalCheckInAnalyzer.collect]).
  final List<GoalDayRecord> recent;

  /// Days before today in this Monday-to-Sunday week that had a lighter goal.
  final int lighterDaysThisWeek;

  /// The habit's own consecutive misses since its last completion.
  final int habitMisses;
  final int perfectStreak;
  final int perfectTailMisses;

  /// Position in today's list, the last tie-breaker.
  final int order;
}

/// An evening offer for one habit.
class LighterDayOffer {
  const LighterDayOffer({
    required this.habit,
    required this.kind,
    required this.values,
    required this.progress,
    required this.usualGoal,
    required this.isDuration,
    required this.daysLeft,
    required this.missedYesterday,
    required this.order,
    this.streakAtRisk,
  });

  final Habit habit;
  final LighterDayKind kind;

  /// Today-only goals to offer, smallest first. When [progress] > 0 the first
  /// one equals it ("18 · done"). Empty for [LighterDayKind.saveStreak].
  final List<int> values;
  final int progress;
  final int usualGoal;
  final bool isDuration;

  /// Lighter days left this week, before taking this one.
  final int daysLeft;
  final bool missedYesterday;
  final int order;

  /// The length of the streak that ends tonight without progress, or null.
  final int? streakAtRisk;

  double get progressRatio => usualGoal <= 0 ? 0 : progress / usualGoal;
}

/// Who gets the evening lighter-day offer, with which values, and how many
/// lighter days are left. Pure Dart, see docs/goal_check_in.md.
class LighterDayPolicy {
  const LighterDayPolicy._();

  static const int allowancePerWeek = 2;
  static const double lowHitRate = 0.5;
  static const int minRecentDays = 4;

  /// Monday of [day]'s week, at midnight.
  static DateTime weekStart(DateTime day) =>
      addCalendarDays(DateTime(day.year, day.month, day.day), -(day.weekday - 1));

  /// Days of this week before [today] where habit [habitId] had a lighter goal.
  static int lighterDaysThisWeek({
    required Iterable<Day> days,
    required int habitId,
    required DateTime today,
  }) {
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = weekStart(todayDate);
    var count = 0;
    for (final day in days) {
      final date = DateTime(day.date.year, day.date.month, day.date.day);
      if (date.isBefore(start) || !date.isBefore(todayDate)) continue;
      for (final h in day.habits) {
        if (h.id == habitId && h.hasDayGoal) {
          count++;
          break;
        }
      }
    }
    return count;
  }

  /// Today-only goals for a habit with [progress] of [goal] logged. Rounded
  /// down to the step for the usual goal's size, at least one step.
  static List<int> offeredValues({
    required int progress,
    required int goal,
    required bool isDuration,
  }) {
    final step = GoalSteps.stepFor(goal, isDuration: isDuration);
    final out = <int>[];
    void add(int v) {
      if (v < goal && !out.contains(v)) out.add(v);
    }

    if (progress > 0) {
      if (progress >= goal) return const [];
      add(progress);
      for (final f in const [1 / 3, 2 / 3]) {
        final v = GoalSteps.roundDownTo(progress + (goal - progress) * f, step);
        if (v > progress) add(v);
      }
    } else {
      for (final f in const [0.25, 0.40, 0.60]) {
        final v = GoalSteps.roundDownTo(goal * f, step);
        add(v < step ? step : v);
      }
    }
    return out.take(3).toList();
  }

  static bool _tracksGoal(Habit h) =>
      h.trackingType == HabitTrackingType.amount ||
      h.trackingType == HabitTrackingType.duration;

  /// The offer for one habit, or null when it doesn't qualify.
  static LighterDayOffer? evaluate(LighterDayInput input) {
    final h = input.habit;
    if (h.optional || !_tracksGoal(h) || !input.scheduledToday) return null;
    if (!GoalCheckInAnalyzer.supports(h)) return null;
    if (h.completed || h.skipped || h.isPaused == true || h.hasDayGoal) {
      return null;
    }

    final isDuration = h.trackingType == HabitTrackingType.duration;
    final goal = isDuration ? h.duration : h.amount;
    final progress = isDuration ? h.durationCompleted : h.amountCompleted;
    if (goal <= 0) return null;

    final daysLeft = (allowancePerWeek - input.lighterDaysThisWeek).clamp(
      0,
      allowancePerWeek,
    );
    final step = GoalSteps.stepFor(goal, isDuration: isDuration);
    final goalBigEnough = goal >= 2 * step;

    final previous = input.recent.isEmpty ? null : input.recent.last;
    final missedYesterday =
        previous != null && !previous.skipped && !previous.met;

    // the streak ends at midnight if nothing gets logged today
    int? streakAtRisk;
    if (progress == 0) {
      if (h.streak > 0 && input.habitMisses >= kStreakMissTolerance) {
        streakAtRisk = h.streak;
      } else if (input.perfectStreak > 0 &&
          input.perfectTailMisses >= kStreakMissTolerance) {
        streakAtRisk = input.perfectStreak;
      }
    }

    if (streakAtRisk != null) {
      final canLighten = daysLeft > 0 && goalBigEnough;
      return LighterDayOffer(
        habit: h,
        kind: canLighten ? LighterDayKind.lighter : LighterDayKind.saveStreak,
        values:
            canLighten
                ? offeredValues(
                  progress: progress,
                  goal: goal,
                  isDuration: isDuration,
                )
                : const [],
        progress: progress,
        usualGoal: goal,
        isDuration: isDuration,
        daysLeft: daysLeft,
        missedYesterday: missedYesterday,
        order: input.order,
        streakAtRisk: streakAtRisk,
      );
    }

    if (daysLeft == 0 || !goalBigEnough) return null;

    final hasRecentMisses = h.streak > 0 && input.habitMisses > 0;
    final qualifying = GoalCheckInAnalyzer.qualifying(input.recent, goal);
    final lowHit =
        qualifying.length >= minRecentDays &&
        GoalCheckInAnalyzer.hitRate(qualifying) < lowHitRate;
    if (!missedYesterday && !hasRecentMisses && !lowHit) return null;

    final values = offeredValues(
      progress: progress,
      goal: goal,
      isDuration: isDuration,
    );
    if (values.isEmpty) return null;
    return LighterDayOffer(
      habit: h,
      kind: LighterDayKind.lighter,
      values: values,
      progress: progress,
      usualGoal: goal,
      isDuration: isDuration,
      daysLeft: daysLeft,
      missedYesterday: missedYesterday,
      order: input.order,
    );
  }

  /// The highest-priority offer: a streak ending tonight, then missed
  /// yesterday, then the closest to its goal, then list order.
  static LighterDayOffer? pick(Iterable<LighterDayOffer> offers) {
    final list = offers.toList();
    if (list.isEmpty) return null;
    list.sort((a, b) {
      final risk = (b.streakAtRisk != null ? 1 : 0) -
          (a.streakAtRisk != null ? 1 : 0);
      if (risk != 0) return risk;
      final missed = (b.missedYesterday ? 1 : 0) - (a.missedYesterday ? 1 : 0);
      if (missed != 0) return missed;
      final ratio = b.progressRatio.compareTo(a.progressRatio);
      if (ratio != 0) return ratio;
      return a.order.compareTo(b.order);
    });
    return list.first;
  }
}
