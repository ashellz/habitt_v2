import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:hive_ce/hive.dart';

class StatsProvider extends ChangeNotifier {
  final daysBox = Hive.box<Day>('days');

  int _habitsCompleted = 0;
  bool shouldRefresh = false;

  get habitsCompleted => getHabitsCompleted();

  int getHabitsCompleted() {
    if (_habitsCompleted == 0) {
      refreshStats(notifiy: false);
      return _habitsCompleted;
    }
    return _habitsCompleted;
  }

  void refreshStats({bool notifiy = true}) {
    _habitsCompleted = refreshHabitsCompleted();
    shouldRefresh = false;
    if (notifiy) {
      notifyListeners();
    }
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
}
