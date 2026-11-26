import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/util/date_key.dart';

/// Which way a goal suggestion goes.
enum GoalDirection { lower, raise }

/// How a single day looked against the usual goal, for the 14 small marks on a
/// suggestion card.
enum GoalDayMark { met, partial, missed }

/// One concluded day of a habit, read from its `Day` snapshot. [goal] and
/// [value] are in the habit's unit (a count, or seconds for duration habits).
class GoalDayRecord {
  const GoalDayRecord({
    required this.date,
    required this.goal,
    required this.value,
    this.lighter = false,
    this.skipped = false,
  });

  final DateTime date;

  /// The usual goal that day (not the lighter one).
  final int goal;

  /// What was really logged.
  final int value;

  /// The day was completed with a lighter goal ([Habit.dayGoal]).
  final bool lighter;
  final bool skipped;

  bool get met => goal > 0 && value >= goal;
  double get ratio => goal <= 0 ? 0 : value / goal;

  GoalDayMark get mark =>
      met
          ? GoalDayMark.met
          : (value > 0 ? GoalDayMark.partial : GoalDayMark.missed);
}

/// A suggestion to change a habit's usual goal, with the facts its card shows.
class GoalSuggestion {
  const GoalSuggestion({
    required this.direction,
    required this.currentValue,
    required this.suggestedValue,
    required this.daysUsed,
    required this.daysMet,
    required this.daysPastGoal,
    required this.typicalValue,
    required this.marks,
    this.lighterDays = 0,
  });

  final GoalDirection direction;
  final int currentValue;
  final int suggestedValue;

  /// Qualifying days the suggestion is based on.
  final int daysUsed;
  final int daysMet;

  /// Days at 1.2 times the goal or more.
  final int daysPastGoal;

  /// The rounded typical value (median) behind the suggestion.
  final int typicalValue;

  /// Oldest first, one per qualifying day.
  final List<GoalDayMark> marks;

  /// Qualifying days completed with a lighter goal.
  final int lighterDays;
}

/// Clean rounding steps shared by goal suggestions and lighter-day values.
/// Durations are in seconds.
class GoalSteps {
  const GoalSteps._();

  static int stepFor(int value, {required bool isDuration}) {
    if (isDuration) {
      if (value < 10 * 60) return 60;
      if (value < 2 * 3600) return 5 * 60;
      return 15 * 60;
    }
    if (value < 10) return 1;
    if (value < 100) return 5;
    return 10;
  }

  /// [value] rounded down to the step for its own size.
  static int roundDown(num value, {required bool isDuration}) {
    final step = stepFor(value.floor(), isDuration: isDuration);
    return (value ~/ step) * step;
  }

  /// [value] rounded down to [step].
  static int roundDownTo(num value, int step) => (value ~/ step) * step;
}

/// Works out goal suggestions from what was really logged. Pure Dart, see
/// docs/goal_check_in.md for the rules.
class GoalCheckInAnalyzer {
  const GoalCheckInAnalyzer._();

  static const int windowDays = 14;
  static const int minDays = 7;
  static const int recentDays = 7;
  static const int minRecentDays = 4;

  static const double lowerHitRate = 0.40;
  static const int lowerLighterDays = 3;
  // the same share of the 7-day half window, rounded up
  static const int lowerLighterDaysRecent = 2;
  static const double raiseHitRate = 0.85;
  static const double raisePastRatio = 1.2;
  static const double raisePastShare = 0.60;
  static const double raiseCap = 1.5;
  static const double allOrNothingZeroShare = 0.60;
  static const int allOrNothingMaxPartials = 2;

  /// Whether goal suggestions apply to [habit] at all.
  static bool supports(Habit habit) =>
      !habit.optional &&
      (habit.trackingType == HabitTrackingType.amount ||
          habit.trackingType == HabitTrackingType.duration) &&
      // sleep is minutes with a tolerance, not a goal to lower or raise
      habit.healthMetric != HealthMetricType.sleep &&
      _usualGoal(habit) > 0;

  static int _usualGoal(Habit habit) =>
      habit.trackingType == HabitTrackingType.duration
          ? habit.duration
          : habit.amount;

  /// The concluded days of [habitId] in the [windowDays] calendar days before
  /// [today], oldest first. Days the habit was inactive on
  /// ([isInactiveOnDay]) or deleted are left out.
  static List<GoalDayRecord> collect({
    required Iterable<Day> days,
    required int habitId,
    required DateTime today,
    bool Function(DateTime day)? isInactiveOnDay,
  }) {
    final todayDate = DateTime(today.year, today.month, today.day);
    final from = addCalendarDays(todayDate, -windowDays);
    final records = <GoalDayRecord>[];
    for (final day in days) {
      final date = DateTime(day.date.year, day.date.month, day.date.day);
      if (!date.isBefore(todayDate) || date.isBefore(from)) continue;
      Habit? h;
      for (final candidate in day.habits) {
        if (candidate.id == habitId) {
          h = candidate;
          break;
        }
      }
      if (h == null || h.isDeleted == true) continue;
      if (!h.hasAnyProgress() && (isInactiveOnDay?.call(date) ?? false)) {
        continue;
      }
      final isDuration = h.trackingType == HabitTrackingType.duration;
      records.add(
        GoalDayRecord(
          date: date,
          goal: isDuration ? h.duration : h.amount,
          value: isDuration ? h.durationCompleted : h.amountCompleted,
          lighter: h.hasDayGoal && h.completed,
          skipped: h.skipped,
        ),
      );
    }
    records.sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  /// The days [analyze] scores: not skipped, at [currentGoal].
  static List<GoalDayRecord> qualifying(
    List<GoalDayRecord> days,
    int currentGoal,
  ) =>
      days.where((d) => !d.skipped && d.goal == currentGoal).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// A suggestion for a habit whose usual goal is [currentGoal], or null.
  /// [blocked] directions are in cooldown and never suggested.
  static GoalSuggestion? analyze({
    required int currentGoal,
    required bool isDuration,
    required List<GoalDayRecord> days,
    Set<GoalDirection> blocked = const {},
  }) {
    if (currentGoal <= 0) return null;
    final qual = qualifying(days, currentGoal);
    if (qual.length < minDays) return null;
    if (isAllOrNothing(qual)) return null;

    final full = _evaluate(qual, currentGoal, isDuration, lowerLighterDays);
    if (full == null || blocked.contains(full.direction)) return null;

    final recent = qual.sublist(
      qual.length > recentDays ? qual.length - recentDays : 0,
    );
    if (recent.length < minRecentDays) return null;
    final recentResult = _evaluate(
      recent,
      currentGoal,
      isDuration,
      lowerLighterDaysRecent,
    );
    if (recentResult?.direction != full.direction) return null;

    return GoalSuggestion(
      direction: full.direction,
      currentValue: currentGoal,
      suggestedValue: full.value,
      daysUsed: qual.length,
      daysMet: qual.where((d) => d.met).length,
      daysPastGoal: qual.where((d) => d.ratio >= raisePastRatio).length,
      typicalValue: full.typical,
      marks: [for (final d in qual) d.mark],
      lighterDays: qual.where((d) => d.lighter).length,
    );
  }

  /// Done fully or not at all: most days below the goal had nothing logged and
  /// hardly any were partial. A smaller goal is the wrong advice then.
  static bool isAllOrNothing(List<GoalDayRecord> days) {
    final below = days.where((d) => !d.met).toList();
    if (below.isEmpty) return false;
    final zeros = below.where((d) => d.value == 0).length;
    final partials = below.length - zeros;
    return zeros / below.length >= allOrNothingZeroShare &&
        partials < allOrNothingMaxPartials;
  }

  /// Share of [days] that met the goal.
  static double hitRate(List<GoalDayRecord> days) =>
      days.isEmpty ? 0 : days.where((d) => d.met).length / days.length;

  static ({GoalDirection direction, int value, int typical})? _evaluate(
    List<GoalDayRecord> days,
    int goal,
    bool isDuration,
    int lighterThreshold,
  ) {
    final hit = hitRate(days);
    final lighterDays = days.where((d) => d.lighter).length;

    if (hit < lowerHitRate || lighterDays >= lighterThreshold) {
      // usually short: what a typical day with any progress reaches. Only
      // lighter days: what the days below the goal reach (the met days would
      // put the median at the goal).
      final onlyLighter = hit >= lowerHitRate;
      final nonZero = [
        for (final d in days)
          if (d.value > 0 && (!onlyLighter || !d.met)) d.value,
      ];
      if (nonZero.isEmpty) return null;
      final typical = GoalSteps.roundDown(
        _median(nonZero),
        isDuration: isDuration,
      );
      if (typical <= 0 || typical >= goal) return null;
      return (direction: GoalDirection.lower, value: typical, typical: typical);
    }

    final pastShare =
        days.where((d) => d.ratio >= raisePastRatio).length / days.length;
    if (hit >= raiseHitRate && pastShare >= raisePastShare) {
      final median = _median([for (final d in days) d.value]);
      final typical = GoalSteps.roundDown(median, isDuration: isDuration);
      final capped = median > goal * raiseCap ? goal * raiseCap : median;
      final value = GoalSteps.roundDown(capped, isDuration: isDuration);
      if (value <= goal) return null;
      return (direction: GoalDirection.raise, value: value, typical: typical);
    }
    return null;
  }

  static double _median(List<int> values) {
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid].toDouble();
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
