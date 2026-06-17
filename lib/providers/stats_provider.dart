import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
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

/// Current streak = perfect days in the ongoing run (the run reaching the most
/// recent day). [chronological] is oldest → newest, excluding today. Walks
/// newest → oldest: a perfect day extends the run and resets tolerance;
/// partial/none are neutral skips; a miss consumes tolerance and the run breaks
/// once tolerance is exhausted.
int computeCurrentStreak(List<DayCompletionStatus> chronological) {
  int streak = 0;
  int missesLeft = kStreakMissTolerance;
  for (int i = chronological.length - 1; i >= 0; i--) {
    switch (chronological[i]) {
      case DayCompletionStatus.perfect:
        streak++;
        missesLeft = kStreakMissTolerance;
      case DayCompletionStatus.partial:
      case DayCompletionStatus.none:
        break; // neutral
      case DayCompletionStatus.miss:
        if (missesLeft > 0) {
          missesLeft--;
        } else {
          return streak;
        }
    }
  }
  return streak;
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

class StatsProvider extends ChangeNotifier {
  final daysBox = Hive.box<Day>('days');

  int _habitsCompleted = -1;
  int _highestAmountOfHabitsLastWeek = -1;
  int _completionRateLastWeek = -1;
  List<double> _habitsCompletedLastWeek = List.generate(7, (i) => -1);
  int _perfectDaysStreak = -1;
  int _longestPerfectDaysStreak = -1;
  List<StatsType> _refreshList = [];
  SharedPreferences? prefs;

  int _dataVersion = 0;
  int _cachedVersion = -1;
  Object? _cachedHabitsRef;
  Map<DateTime, double>? _cachedAllDaysProgress;
  Map<DateTime, DayCompletionStatus>? _cachedDayStatuses;

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

    for (final day in daysBox.values) {
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
  Map<DateTime, DayCompletionStatus> getDayCompletionStatuses(HabitProvider hp) {
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

  int getCompletionRateLastWeek() {
    if (_completionRateLastWeek == -1) {
      _completionRateLastWeek = refreshCompletionRateLastWeek();
    }
    return _completionRateLastWeek;
  }

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
        daysBox.values
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
    final statuses = [
      for (final d in _streakDaysExcludingToday()) d.status,
    ];
    final longest = computeLongestStreak(statuses);
    _longestPerfectDaysStreak = longest;
    prefs?.setInt(longestPerfectDaysStreakKey, longest);
  }

  int refreshHabitsCompleted() {
    int habitsCompleted = 0;
    for (final day in daysBox.values) {
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
    final orderedDays = daysBox.values.toList();
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

  int refreshCompletionRateLastWeek() {
    int totalHabits = 0;
    int completedHabits = 0;

    final now = DateTime.now();

    if (daysBox.values.isEmpty) {
      return 0;
    }

    // First we order the days by date
    final orderedDays = daysBox.values.toList();
    orderedDays.sort((a, b) => b.date.compareTo(a.date));

    // We remove today
    orderedDays.removeWhere(
      (day) =>
          day.date.year == now.year &&
          day.date.month == now.month &&
          day.date.day == now.day,
    );

    // Then we check the last 7 days
    for (int i = 0; i < 6 && i < orderedDays.length; i++) {
      final day = orderedDays[i];
      for (final habit in _countingHabits(day)) {
        if (habit.optional) continue;
        totalHabits++;
        if (habit.completed) {
          completedHabits++;
        }
      }
    }

    if (totalHabits == 0) {
      return 0;
    }

    return (completedHabits / totalHabits * 100).clamp(0, 100).toInt();
  }

  List<double> getCompletionRateLastWeekByDay(HabitProvider hp) {
    final allDays = _allDaysIncludingToday(hp);
    final daysByDate = <DateTime, Day>{};

    for (final day in allDays) {
      daysByDate[DateTime(day.date.year, day.date.month, day.date.day)] = day;
    }

    return List.generate(7, (index) {
      final targetDate = DateTime.now().subtract(Duration(days: 6 - index));
      final normalizedDate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final day = daysByDate[normalizedDate];

      if (day == null) {
        return 0.0;
      }

      int requiredHabits = 0;
      int completedHabits = 0;

      for (final habit in _countingHabits(day)) {
        if (habit.optional) continue;
        requiredHabits++;
        if (habit.completed) {
          completedHabits++;
        }
      }

      if (requiredHabits == 0) {
        return 0.0;
      }

      return (completedHabits / requiredHabits * 100).clamp(0, 100);
    });
  }

  List<double> refreshHabitsCompletedLastWeek() {
    List<double> habitsCompletedLastWeek = List.generate(7, (i) => 0);

    // First we order the days by date
    final orderedDays = daysBox.values.toList();
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
    final streak = computeCurrentStreak(statuses);
    final longest = computeLongestStreak(statuses);

    for (final d in days) {
      debugPrint(
        '[streak] ${d.date.toIso8601String().split("T").first} — ${d.status.name}',
      );
    }
    debugPrint('[streak] current=$streak longest=$longest');

    // Keep longest in sync on the lazy path too (cheap, same data).
    if (longest > _longestPerfectDaysStreak) {
      _longestPerfectDaysStreak = longest;
      prefs?.setInt(longestPerfectDaysStreakKey, longest);
    }

    return streak;
  }
}
