import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:hive_ce/hive.dart';

enum StatsType { habitsCompleted, highestAmountOfHabitsLastWeek }

class StatsProvider extends ChangeNotifier {
  final daysBox = Hive.box<Day>('days');

  int _habitsCompleted = -1;
  int _highestAmountOfHabitsLastWeek = -1;
  List<StatsType> _refreshList = [];

  get habitsCompleted => getHabitsCompleted();
  get highestAmountOfHabitsLastWeek => getHighestAmountOfHabitsLastWeek();

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

  void refreshStats() {
    if (_refreshList.contains(StatsType.habitsCompleted)) {
      _habitsCompleted = refreshHabitsCompleted();
    }
    if (_refreshList.contains(StatsType.highestAmountOfHabitsLastWeek)) {
      _highestAmountOfHabitsLastWeek = refreshHighestAmountOfHabitsLastWeek();
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
}
