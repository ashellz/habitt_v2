import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/models/streak_health.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StatsType {
  habitsCompleted,
  highestAmountOfHabitsLastWeek,
  perfectDaysStreak,
}

/// How a single day counts toward streaks. Single source of truth shared by the
/// streak number ([StatsProvider.refreshPerfectStreak]) and the calendar runs
/// ([StreakCalendar]) so they can never disagree.
///
/// - [perfect] — every required (non-optional) habit is completed or skipped.
/// - [partial] — not perfect, but EVERY required habit has at least some
///   progress (completed/skipped or partial amount/duration). Treated as a
///   neutral "skip": it neither extends nor breaks a streak.
/// - [miss] — at least one required habit has zero progress. Consumes streak
///   miss-tolerance.
/// - [none] — no required habits that day (empty/all-optional). Neutral, like
///   [partial].
enum DayCompletionStatus { perfect, partial, miss, none }

/// How many consecutive misses are tolerated within a streak before it breaks.
/// The (tolerance + 1)th consecutive miss breaks the run. Shared by the streak
/// number ([computeCurrentStreak]) and the calendar runs so they always agree.
const int kStreakMissTolerance = 2;

/// Classifies a day's (already schedule-filtered) habits per
/// [DayCompletionStatus]. A habit "has progress" when it is completed, skipped,
/// or has any tracked amount/duration logged. The day is [DayCompletionStatus.perfect]
/// when all required habits are completed/skipped, [DayCompletionStatus.partial]
/// when *every* required habit has at least some progress (but not all
/// complete), [DayCompletionStatus.miss] when at least one required habit has no
/// progress, and [DayCompletionStatus.none] when there are no required habits.
DayCompletionStatus classifyDayStatus(List<Habit> habits) {
  int required = 0;
  int satisfied = 0; // completed or skipped
  int withProgress = 0; // satisfied, or partial amount/duration

  for (final habit in habits) {
    if (habit.optional) continue;
    required++;

    final isSatisfied = habit.completed || habit.skipped;
    final hasProgress =
        isSatisfied ||
        (habit.tracksAmount && habit.amountCompleted > 0) ||
        (habit.tracksDuration && habit.durationCompleted > 0);

    if (isSatisfied) satisfied++;
    if (hasProgress) withProgress++;
  }

  if (required == 0) return DayCompletionStatus.none;
  if (satisfied >= required) return DayCompletionStatus.perfect;
  if (withProgress >= required) return DayCompletionStatus.partial;
  return DayCompletionStatus.miss;
}

({int streak, int tailMisses}) computeCurrentStreak(
  List<DayCompletionStatus> chronological,
) {
  int streak = 0;
  int missesLeft = kStreakMissTolerance;
  int tailMisses = 0;
  bool tailSettled = false;

  // going from newest to oldest
  for (int i = chronological.length - 1; i >= 0; i--) {
    switch (chronological[i]) {
      case DayCompletionStatus.perfect:
        streak++;
        missesLeft = kStreakMissTolerance;
        // found a perfect day, tailmisses will stop counting after this point
        tailSettled = true;
      case DayCompletionStatus.partial:
      case DayCompletionStatus.none:
        break; // neutral
      case DayCompletionStatus.miss:
        if (!tailSettled) tailMisses++;
        if (missesLeft > 0) {
          missesLeft--;
        } else {
          return (streak: streak, tailMisses: tailMisses);
        }
    }
  }
  return (streak: streak, tailMisses: tailMisses);
}

/// Longest streak across all history, using the same run rules as
/// [computeCurrentStreak]. Leading misses before the first perfect day (no run
/// yet) are ignored.
int computeLongestStreak(List<DayCompletionStatus> chronological) {
  int longest = 0;
  int current = 0;
  int missesLeft = kStreakMissTolerance;
  bool inRun = false;

  for (final status in chronological) {
    switch (status) {
      case DayCompletionStatus.perfect:
        current++;
        missesLeft = kStreakMissTolerance;
        inRun = true;
        if (current > longest) longest = current;
      case DayCompletionStatus.partial:
      case DayCompletionStatus.none:
        break; // neutral
      case DayCompletionStatus.miss:
        if (!inRun) break; // no run started yet
        if (missesLeft > 0) {
          missesLeft--;
        } else {
          current = 0;
          inRun = false;
          missesLeft = kStreakMissTolerance;
        }
    }
  }
  return longest;
}

/// Required (non-optional) and completed habits of one day.
typedef _CompletionCounts = ({int required, int completed});

class StatsProvider extends ChangeNotifier {
  final daysBox = Hive.box<Day>('days');

  /// Stored days, minus any dated after today. Future days can only exist if
  /// the device clock was moved ahead and back again; they hold no real
  /// history and would otherwise count as misses and break streaks.
  Iterable<Day> get _daysUpToToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return daysBox.values.where(
      (d) => !DateTime(d.date.year, d.date.month, d.date.day).isAfter(today),
    );
  }

  int _habitsCompleted = -1;
  int _highestAmountOfHabitsLastWeek = -1;
  List<double> _habitsCompletedLastWeek = List.generate(7, (i) => -1);
  int _perfectDaysStreak = -1;
  int _longestPerfectDaysStreak = -1;

  /// Miss tolerance already spent on the current run. Derived, never persisted —
  /// [refreshPerfectStreak] is its only writer, so it is refreshed on exactly
  /// the paths that refresh [_perfectDaysStreak].
  int _perfectDaysTailMisses = 0;
  List<StatsType> _refreshList = [];
  SharedPreferences? prefs;

  int _dataVersion = 0;
  int _cachedVersion = -1;
  Object? _cachedHabitsRef;
  Map<DateTime, double>? _cachedAllDaysProgress;
  Map<DateTime, DayCompletionStatus>? _cachedDayStatuses;
  Map<DateTime, _CompletionCounts>? _cachedPastCompletionCounts;

  /// Back-reference set by [HabitProvider.updateDependencies]. Used only to
  /// schedule-filter day snapshots via [HabitProvider.habitsCountingForDay] so
  /// that completion stats agree with the home "last week" progress.
  HabitProvider? _habitProvider;

  void attachHabitProvider(HabitProvider hp) {
    _habitProvider = hp;
  }

  /// The habits in [day] that count toward completion stats for that date.
  /// Filters the raw snapshot through the schedule rule so habits unioned in by
  /// sync (but not scheduled that day, and left incomplete) are not miscounted
  /// as unmet requirements. Falls back to the raw list if no HabitProvider is
  /// attached yet (early startup).
  List<Habit> _countingHabits(Day day) {
    final hp = _habitProvider;
    if (hp == null) return day.habits;
    return hp.habitsCountingForDay(day.date, day.habits);
  }

  static const String longestPerfectDaysStreakKey = 'longestPerfectDaysStreak';

  StatsProvider({this.prefs}) {
    _longestPerfectDaysStreak =
        prefs?.getInt(longestPerfectDaysStreakKey) ?? -1;
  }

  get habitsCompleted => getHabitsCompleted();
  get highestAmountOfHabitsLastWeek => getHighestAmountOfHabitsLastWeek();
  get habitsCompletedLastWeek => getHabitsCompletedLastWeek();
  get completionRateLastWeek => getCompletionRateLastWeek();
  int get perfectDaysStreak => getPerfectStreak();
  int get longestPerfectDaysStreak => _longestPerfectDaysStreak;

  // Perfect streak health stuff

  int get perfectDaysTailMisses {
    getPerfectStreak();
    return _perfectDaysTailMisses;
  }

  /// Today's live completion status
  DayCompletionStatus get todayCompletionStatus {
    final hp = _habitProvider;
    if (hp == null) return DayCompletionStatus.none;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return getDayCompletionStatuses(hp)[today] ?? DayCompletionStatus.none;
  }

  StreakHealth get perfectDaysHealth => resolveStreakHealth(
    streak: perfectDaysStreak,
    tailMisses: perfectDaysTailMisses,
    todayIsSecure: todayCompletionStatus == DayCompletionStatus.perfect,
  );

  set perfectDaysStreak(int value) {
    _perfectDaysStreak = value;
    notifyListeners();
  }

  bool shouldRefresh(StatsType type) => _refreshList.contains(type);

  void addShouldRefresh(StatsType type) {
    _refreshList.add(type);
    notifyListeners();
  }

  List<Day> _allDaysIncludingToday(HabitProvider hp) {
    final allDays = <Day>[];
    final now = DateTime.now();

    for (final day in _daysUpToToday) {
      // Do not keep persisted "today"; replace with live today's habits.
      if (day.date.year == now.year &&
          day.date.month == now.month &&
          day.date.day == now.day) {
        continue;
      }
      allDays.add(day);
    }

    final nowNormalized = DateTime(now.year, now.month, now.day);
    allDays.add(
      Day(
        date: nowNormalized,
        habits: hp.todaysHabits,
        timestamp: DateTime.now(),
      ),
    );

    return allDays;
  }

  void _maybeInvalidateMapCache(HabitProvider hp) {
    if (_cachedVersion != _dataVersion ||
        !identical(_cachedHabitsRef, hp.todaysHabits)) {
      _cachedAllDaysProgress = null;
      _cachedDayStatuses = null;
      _cachedPastCompletionCounts = null;
      _cachedVersion = _dataVersion;
      _cachedHabitsRef = hp.todaysHabits;
    }
  }

  Map<DateTime, double> getAllDaysProgress(HabitProvider hp) {
    _maybeInvalidateMapCache(hp);
    if (_cachedAllDaysProgress != null) return _cachedAllDaysProgress!;

    final allDays = _allDaysIncludingToday(hp);
    final Map<DateTime, double> daysProgress = {};
    for (final day in allDays) {
      daysProgress[day.date] = getDayProgress(day.date, _countingHabits(day));
    }
    _cachedAllDaysProgress = daysProgress;
    return daysProgress;
  }

  /// Per-day [DayCompletionStatus] for every tracked day (today uses the live
  /// habit set). Single source of truth for streak visuals + the streak number.
  Map<DateTime, DayCompletionStatus> getDayCompletionStatuses(
    HabitProvider hp,
  ) {
    _maybeInvalidateMapCache(hp);
    if (_cachedDayStatuses != null) return _cachedDayStatuses!;

    final allDays = _allDaysIncludingToday(hp);
    final statuses = <DateTime, DayCompletionStatus>{};
    for (final day in allDays) {
      final normalizedDate = DateTime(
        day.date.year,
        day.date.month,
        day.date.day,
      );
      statuses[normalizedDate] = classifyDayStatus(_countingHabits(day));
    }
    _cachedDayStatuses = statuses;
    return statuses;
  }

  double getDayProgress(DateTime date, List<Habit> habits) {
    int totalHabits = 0;

    for (final habit in habits) {
      if (habit.optional) {
        continue;
      }
      totalHabits++;
    }

    if (totalHabits == 0) {
      return 0.0;
    }

    final completedWeight = habits.fold<double>(0.0, (sum, habit) {
      if (habit.optional) return sum;

      if (habit.completed) {
        return sum + 1.0;
      }

      if (habit.tracksAmount) {
        if (habit.amount <= 0) {
          return sum;
        }
        return sum + (habit.amountCompleted / habit.amount).clamp(0.0, 1.0);
      }

      if (habit.tracksDuration) {
        if (habit.duration <= 0) {
          return sum;
        }
        return sum + (habit.durationCompleted / habit.duration).clamp(0.0, 1.0);
      }

      return sum;
    });

    return (completedWeight / totalHabits).clamp(0.0, 1.0);
  }

  int getHabitsCompleted() {
    if (_habitsCompleted == -1) {
      _habitsCompleted = refreshHabitsCompleted();
      return _habitsCompleted;
    }
    return _habitsCompleted;
  }

  int getHighestAmountOfHabitsLastWeek() {
    if (_highestAmountOfHabitsLastWeek != -1) {
      return _highestAmountOfHabitsLastWeek;
    }

    _highestAmountOfHabitsLastWeek = refreshHighestAmountOfHabitsLastWeek();
    return _highestAmountOfHabitsLastWeek;
  }

  List<double> getHabitsCompletedLastWeek() {
    if (_habitsCompletedLastWeek.every((element) => element == -1)) {
      _habitsCompletedLastWeek = refreshHabitsCompletedLastWeek();
    }
    return _habitsCompletedLastWeek;
  }

  // not cached: today's completions change it all day long
  int getCompletionRateLastWeek() => getCompletionRate(StatsRange.week);

  int getPerfectStreak() {
    if (_perfectDaysStreak == -1) {
      _perfectDaysStreak = refreshPerfectStreak();
    }
    return _perfectDaysStreak;
  }

  void refreshStats({bool force = false}) {
    _dataVersion++;
    if (_refreshList.contains(StatsType.habitsCompleted) || force) {
      _habitsCompleted = refreshHabitsCompleted();
      _habitsCompletedLastWeek = refreshHabitsCompletedLastWeek();
    }
    if (_refreshList.contains(StatsType.highestAmountOfHabitsLastWeek) ||
        force) {
      _highestAmountOfHabitsLastWeek = refreshHighestAmountOfHabitsLastWeek();
    }
    if (_refreshList.contains(StatsType.perfectDaysStreak) || force) {
      _perfectDaysStreak = refreshPerfectStreak();
      recalculateLongestPerfectDaysStreak();
    }

    _refreshList = [];

    notifyListeners();
  }

  /// Per-day (date, status) records (oldest → newest) for every tracked day
  /// except today, classified through the schedule filter. Today is excluded
  /// because it is almost never complete at check time.
  List<({DateTime date, DayCompletionStatus status})>
  _streakDaysExcludingToday() {
    final now = DateTime.now();
    final days =
        _daysUpToToday
            .where(
              (d) =>
                  !(d.date.year == now.year &&
                      d.date.month == now.month &&
                      d.date.day == now.day),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return [
      for (final d in days)
        (date: d.date, status: classifyDayStatus(_countingHabits(d))),
    ];
  }

  /// Scans all historical days to find the true longest perfect-days streak.
  /// Updates both the in-memory field and SharedPreferences.
  void recalculateLongestPerfectDaysStreak() {
    final statuses = [for (final d in _streakDaysExcludingToday()) d.status];
    final longest = computeLongestStreak(statuses);
    _longestPerfectDaysStreak = longest;
    prefs?.setInt(longestPerfectDaysStreakKey, longest);
  }

  int refreshHabitsCompleted() {
    int habitsCompleted = 0;
    for (final day in _daysUpToToday) {
      for (final habit in day.habits) {
        if (habit.completed) {
          habitsCompleted++;
        }
      }
    }
    return habitsCompleted;
  }

  int refreshHighestAmountOfHabitsLastWeek() {
    int highestAmountOfHabits = 0;

    // First we order the days by date
    final orderedDays = _daysUpToToday.toList();
    orderedDays.sort((a, b) => b.date.compareTo(a.date));

    // Then we check the last 7 days
    for (int i = 0; i < 7 && i < orderedDays.length; i++) {
      final day = orderedDays[i];
      int tracking = 0;
      for (final habit in _countingHabits(day)) {
        if (habit.optional) continue;
        tracking++;
      }
      if (tracking > highestAmountOfHabits) {
        highestAmountOfHabits = tracking;
      }
    }

    return highestAmountOfHabits;
  }

  int getCompletionRate(StatsRange range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = range.startFor(today);
    final hp = _habitProvider;

    int totalHabits = 0;
    int completedHabits = 0;

    // The days inside the range that are over
    _pastCompletionCounts(hp).forEach((date, counts) {
      if (start != null && date.isBefore(start)) return;
      totalHabits += counts.required;
      completedHabits += counts.completed;
    });

    // Today isn't over: a habit that is already completed counts straight
    // away, one that isn't yet is not a miss and stays out of the ratio.
    final todayCounts = _todayCompletionCounts(hp);
    totalHabits += todayCounts.completed;
    completedHabits += todayCounts.completed;

    if (totalHabits == 0) {
      return 0;
    }

    return (completedHabits / totalHabits * 100).clamp(0, 100).toInt();
  }

  /// Completion rate (0-100) for each of the last [days] days, oldest first,
  /// ending today. Today shows its progress so far, a day without data is 0.
  List<double> getCompletionRateByDay(HabitProvider hp, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final past = _pastCompletionCounts(hp);

    return List.generate(days, (index) {
      final daysAgo = days - 1 - index;
      final counts =
          daysAgo == 0
              ? _todayCompletionCounts(hp)
              : past[DateTime(today.year, today.month, today.day - daysAgo)];

      if (counts == null || counts.required == 0) {
        return 0.0;
      }

      return (counts.completed / counts.required * 100).clamp(0, 100);
    });
  }

  /// The earliest stored day, null before anything was tracked.
  DateTime? get firstTrackedDay {
    DateTime? first;
    for (final date in _pastCompletionCounts(_habitProvider).keys) {
      if (first == null || date.isBefore(first)) first = date;
    }
    if (first != null) return first;

    // nothing before today, so today is the first day if it is stored
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hasToday = _daysUpToToday.any(
      (day) => DateTime(day.date.year, day.date.month, day.date.day) == today,
    );
    return hasToday ? today : null;
  }

  /// Completion rate (0-1) of the whole history in 7-day windows counting back
  /// from today, oldest first, each dated by its last day, so the newest one
  /// is the 7D rate. Today counts only its completed habits, like
  /// [getCompletionRate]. Windows without a required habit are left out.
  ({List<DateTime> dates, List<double> values}) getWeeklyCompletionRates(
    HabitProvider hp,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayCounts = _todayCompletionCounts(hp);
    final requiredByWeek = <int, int>{0: todayCounts.completed};
    final completedByWeek = <int, int>{0: todayCounts.completed};

    _pastCompletionCounts(hp).forEach((date, counts) {
      final week = _daysBetween(date, today) ~/ 7;
      requiredByWeek[week] = (requiredByWeek[week] ?? 0) + counts.required;
      completedByWeek[week] = (completedByWeek[week] ?? 0) + counts.completed;
    });

    final weeks =
        requiredByWeek.keys.where((week) => requiredByWeek[week]! > 0).toList()
          ..sort((a, b) => b.compareTo(a));
    return (
      dates: [
        for (final week in weeks)
          DateTime(today.year, today.month, today.day - week * 7),
      ],
      values: [
        for (final week in weeks)
          completedByWeek[week]! / requiredByWeek[week]!,
      ],
    );
  }

  /// Required and completed habits of every stored day that is over, the base
  /// of the completion rates. Cached like [getAllDaysProgress] once a
  /// HabitProvider is attached; today changes all day long and is counted
  /// live by [_todayCompletionCounts].
  Map<DateTime, _CompletionCounts> _pastCompletionCounts(HabitProvider? hp) {
    if (hp != null) {
      _maybeInvalidateMapCache(hp);
      final cached = _cachedPastCompletionCounts;
      if (cached != null) return cached;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final counts = <DateTime, _CompletionCounts>{};
    for (final day in _daysUpToToday) {
      final date = DateTime(day.date.year, day.date.month, day.date.day);
      if (date == today) continue;
      counts[date] = _countCompletion(_countingHabits(day));
    }

    if (hp != null) _cachedPastCompletionCounts = counts;
    return counts;
  }

  /// Today's live counts, from the HabitProvider when one is around.
  _CompletionCounts _todayCompletionCounts(HabitProvider? hp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayDay =
        hp != null
            ? Day(date: today, habits: hp.todaysHabits, timestamp: now)
            : _daysUpToToday
                .where(
                  (day) =>
                      DateTime(day.date.year, day.date.month, day.date.day) ==
                      today,
                )
                .firstOrNull;
    if (todayDay == null) return (required: 0, completed: 0);
    return _countCompletion(_countingHabits(todayDay));
  }

  static _CompletionCounts _countCompletion(List<Habit> habits) {
    int requiredHabits = 0;
    int completedHabits = 0;
    for (final habit in habits) {
      if (habit.optional) continue;
      requiredHabits++;
      if (habit.completed) {
        completedHabits++;
      }
    }
    return (required: requiredHabits, completed: completedHabits);
  }

  // calendar days apart, immune to daylight-saving hour shifts
  static int _daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(
        to.year,
        to.month,
        to.day,
      ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  List<double> refreshHabitsCompletedLastWeek() {
    List<double> habitsCompletedLastWeek = List.generate(7, (i) => 0);

    // First we order the days by date
    final orderedDays = _daysUpToToday.toList();
    orderedDays.sort((a, b) => b.date.compareTo(a.date));

    // Then we check the last 7 days
    for (int i = 0; i < 7 && i < orderedDays.length; i++) {
      final day = orderedDays[i];
      double habitsCompleted = 0;
      for (final habit in _countingHabits(day)) {
        if (habit.optional) continue;
        if (habit.completed) {
          habitsCompleted++;
        } else if (habit.tracksAmount) {
          if (habit.amount > 0) {
            habitsCompleted += (habit.amountCompleted / habit.amount).clamp(
              0.0,
              1.0,
            );
          }
        } else if (habit.tracksDuration) {
          if (habit.duration > 0) {
            habitsCompleted += (habit.durationCompleted / habit.duration).clamp(
              0.0,
              1.0,
            );
          }
        }
      }
      habitsCompletedLastWeek[i] = habitsCompleted;
    }

    // Then we reverse the list
    habitsCompletedLastWeek = habitsCompletedLastWeek.reversed.toList();

    return habitsCompletedLastWeek;
  }

  int refreshPerfectStreak() {
    final days = _streakDaysExcludingToday();
    final statuses = [for (final d in days) d.status];
    final current = computeCurrentStreak(statuses);
    final streak = current.streak;
    _perfectDaysTailMisses = current.tailMisses;
    final longest = computeLongestStreak(statuses);

    // Keep longest in sync on the lazy path too (cheap, same data).
    if (longest > _longestPerfectDaysStreak) {
      _longestPerfectDaysStreak = longest;
      prefs?.setInt(longestPerfectDaysStreakKey, longest);
    }

    return streak;
  }
}
