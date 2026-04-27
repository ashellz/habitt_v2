import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
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
  List<int> _habitsCompletedLastWeek = List.generate(7, (i) => -1);
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

  List<int> getHabitsCompletedLastWeek() {
    if (_habitsCompletedLastWeek.every((element) => element == -1)) {
      _habitsCompletedLastWeek = refreshHabitsCompletedLastWeek();
    }
    return _habitsCompletedLastWeek;
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
    }

    _refreshList = [];

    notifyListeners();
  }

  int refreshHabitsCompleted() {
    int habitsCompleted = 0;
    for (final day in daysBox.values) {
      for (final habit in day.habits) {
        if (habit.completed) {
          habitsCompleted++;
          debugPrint("Completed habit found, {$habitsCompleted} total");
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
      if (day.habits.length > highestAmountOfHabits) {
        highestAmountOfHabits = day.habits.length;
      }
    }

    return highestAmountOfHabits;
  }

  List<int> refreshHabitsCompletedLastWeek() {
    List<int> habitsCompletedLastWeek = List.generate(7, (i) => 0);

    // First we order the days by date
    final orderedDays = daysBox.values.toList();
    orderedDays.sort((a, b) => b.date.compareTo(a.date));

    // Then we check the last 7 days
    for (int i = 0; i < 7 && i < orderedDays.length; i++) {
      final day = orderedDays[i];
      int habitsCompleted = 0;
      for (final habit in day.habits) {
        if (habit.completed) {
          habitsCompleted++;
          debugPrint("Completed habit found, {$habitsCompleted} total");
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

    // Then we check all days from yesterday to the day we started using the app
    // If all habits are completed, we add 1 to the streak
    // Else we stop there
    int longestStreak = 0;

    for (int i = 1; i < orderedDays.length; i++) {
      final day = orderedDays[i];
      int habitsCompleted = 0;
      int habitsSkipped = 0;
      int requiredHabits = 0;
      for (final habit in day.habits) {
        // If habit is optional, we dont count it
        if (habit.optional) continue;
        requiredHabits++;
        if (habit.completed) {
          habitsCompleted++;
          debugPrint("Completed habit found, {$habitsCompleted} total");
        } else if (habit.skipped) {
          habitsSkipped++;
          debugPrint("Skipped habit found, {$habitsSkipped} total");
        }
      }
      if (requiredHabits == 0) continue;

      if (habitsCompleted + habitsSkipped >= requiredHabits) {
        allHabitsCompletedStreak++;
        missedDaysAllowed = 1;
      } else {
        if (missedDaysAllowed > 0) {
          missedDaysAllowed--;
          continue;
        }
        break;
      }
    }

    if (allHabitsCompletedStreak > longestStreak) {
      longestStreak = allHabitsCompletedStreak;
      notifyListeners();
      prefs?.setInt(longestPerfectDaysStreakKey, longestStreak);
    }

    return allHabitsCompletedStreak;
  }
}
