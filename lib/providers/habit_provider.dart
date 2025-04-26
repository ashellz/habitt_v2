import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> habits = [];
  final habitBox = Hive.box<Habit>('habits');
  final daysBox = Hive.box<Day>('days');

  HabitProvider() {
    _loadHabits();
  }

  void _loadHabits() {
    habits = habitBox.values.toList();
  }

  void _saveHabitDay(DateTime day) {
    final DateTime todaySimple = DateTime(day.year, day.month, day.day);

    for (final day in daysBox.values) {
      debugPrint(day.date.toString());
      daysBox.put(todaySimple, day);
    }
  }

  void updateHabitInDB(Habit habit) {
    habitBox.putAt(habitBox.values.toList().indexOf(habit), habit);
  }

  void addHabit(Habit habit) {
    habits.add(habit);
    habitBox.add(habit);
    notifyListeners();
  }

  void removeHabit(Habit habit) {
    habits.remove(habit);
    notifyListeners();
  }

  void completeHabit(int id) {
    final habit = habits.firstWhere((h) => h.id == id);
    habit.completeHabit();
    updateHabitInDB(habit);
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    habits.where((h) => h.id == habit.id).first.updateHabit(habit);
    updateHabitInDB(habit);
    notifyListeners();
  }

  void updateHabitAmountCompleted(int id, int amountCompleted) {
    habits
        .where((h) => h.id == id)
        .first
        .updateHabitAmountCompleted(amountCompleted);
    updateHabitInDB(habits.firstWhere((h) => h.id == id));
    notifyListeners();
  }

  void updateHabitDurationCompleted(int id, int durationCompleted) {
    habits
        .where((h) => h.id == id)
        .first
        .updateHabitDurationCompleted(durationCompleted);
    updateHabitInDB(habits.firstWhere((h) => h.id == id));
    notifyListeners();
  }
}
