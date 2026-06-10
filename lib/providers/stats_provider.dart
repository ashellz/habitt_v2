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

  bool _isPerfectDay(List<Habit> habits) {
    int requiredHabits = 0;
    int completedOrSkipped = 0;

    for (final habit in habits) {
      if (habit.optional) {
        continue;
      }
      requiredHabits++;
      if (habit.completed || habit.skipped) {
        completedOrSkipped++;
      }
    }

    if (requiredHabits == 0) {
      return false;
    }

    return completedOrSkipped >= requiredHabits;
  }

  Map<DateTime, double> getAllDaysProgress(HabitProvider hp) {
    final allDays = _allDaysIncludingToday(hp);

    // Calculating progress for each day 0 - 1

    final Map<DateTime, double> daysProgress = {};

    for (final day in allDays) {
      daysProgress[day.date] = getDayProgress(day.date, day.habits);
    }

    return daysProgress;
  }

  Map<DateTime, bool> getPerfectDayCompletion(HabitProvider hp) {
    final allDays = _allDaysIncludingToday(hp);
    final perfectDayCompletion = <DateTime, bool>{};

    for (final day in allDays) {
      final normalizedDate = DateTime(
        day.date.year,
        day.date.month,
        day.date.day,
      );
      perfectDayCompletion[normalizedDate] = _isPerfectDay(day.habits);
    }

    return perfectDayCompletion;
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

  /// Scans all historical days (oldest → newest) to find the true longest
  /// perfect-days streak. Updates both the in-memory field and SharedPreferences.
  void recalculateLongestPerfectDaysStreak() {
    final allDays = daysBox.values.toList();
    allDays.sort((a, b) => a.date.compareTo(b.date)); // oldest → newest

    final now = DateTime.now();
    allDays.removeWhere(
      (d) =>
          d.date.year == now.year &&
          d.date.month == now.month &&
          d.date.day == now.day,
    );

    int longest = 0;
    int currentRun = 0;
    int missedAllowed = 1;

    for (final day in allDays) {
      int habitsCompleted = 0;
      int habitsSkipped = 0;
      int required = 0;

      for (final habit in day.habits) {
        if (habit.optional) continue;
        required++;
        if (habit.completed) {
          habitsCompleted++;
        } else if (habit.skipped) {
          habitsSkipped++;
        } else if (habit.tracksAmount && habit.amountCompleted > 0) {
          habitsCompleted++;
        } else if (habit.tracksDuration && habit.durationCompleted > 0) {
          habitsCompleted++;
        }
      }

      if (required == 0) continue;

      if (habitsCompleted + habitsSkipped >= required) {
        currentRun++;
        missedAllowed = 2;
        if (currentRun > longest) longest = currentRun;
      } else {
        if (missedAllowed > 0) {
          missedAllowed--;
        } else {
          currentRun = 0;
          missedAllowed = 1;
        }
      }
    }

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
      for (final habit in day.habits) {
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
      for (final habit in day.habits) {
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

      for (final habit in day.habits) {
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
      for (final habit in day.habits) {
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
    int allHabitsCompletedStreak = 0;
    int missedDaysAllowed = 1;

    // First we order the days by date
    final orderedDays = daysBox.values.toList();
    orderedDays.sort((a, b) => b.date.compareTo(a.date));
    debugPrint(
      "Refreshing perfect days streak, first date: ${orderedDays.first.date}, last date: ${orderedDays.last.date}, total days: ${orderedDays.length}",
    );

    // Check all days from yesterday backwards to the day we started using the app.
    // Today is excluded because it is almost never completed at check time.
    // Up to 2 consecutive missed days are tolerated before the streak breaks.
    int longestStreak = 0;

    for (int i = 1; i < orderedDays.length; i++) {
      final day = orderedDays[i];
      int habitsCompleted = 0;
      int habitsSkipped = 0;
      int requiredHabits = 0;
      bool hasPartialProgress = false;

      for (final habit in day.habits) {
        if (habit.optional) continue;
        requiredHabits++;
        if (habit.completed) {
          habitsCompleted++;
        } else if (habit.skipped) {
          habitsSkipped++;
        } else if (habit.tracksAmount && habit.amountCompleted > 0) {
          hasPartialProgress = true;
        } else if (habit.tracksDuration && habit.durationCompleted > 0) {
          hasPartialProgress = true;
        }
      }

      if (requiredHabits == 0) {
        // debugPrint('[streak] ${day.date.toIso8601String().split("T").first} — SKIPPED (no required habits)');
        continue;
      }

      final isPerfect = habitsCompleted + habitsSkipped >= requiredHabits;
      debugPrint(
        '[streak] ${day.date.toIso8601String().split("T").first} — '
        'required=$requiredHabits completed=$habitsCompleted skipped=$habitsSkipped partial=$hasPartialProgress '
        '→ ${isPerfect
            ? "PERFECT (streak=${allHabitsCompletedStreak + 1})"
            : hasPartialProgress
            ? "PARTIAL (neutral)"
            : "MISS (missedLeft=${missedDaysAllowed - 1})"}',
      );

      if (isPerfect) {
        allHabitsCompletedStreak++;
        missedDaysAllowed = 2;
      } else if (hasPartialProgress) {
        // Some incomplete habits have progress — treat as neutral, don't touch streak or miss count.
        continue;
      } else {
        if (missedDaysAllowed > 0) {
          missedDaysAllowed--;
          continue;
        }
        // debugPrint('[streak] → BREAK (no misses left)');
        break;
      }
    }

    if (allHabitsCompletedStreak > longestStreak) {
      longestStreak = allHabitsCompletedStreak;
      prefs?.setInt(longestPerfectDaysStreakKey, longestStreak);
    }

    return allHabitsCompletedStreak;
  }
}
