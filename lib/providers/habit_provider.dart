import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> habits = [];

  HabitProvider() {
    _loadHabits();
  }

  void _loadHabits() {
    // TODO: Load habits from database
  }

  void addHabit(Habit habit) {
    habits.add(habit);
    notifyListeners();
  }

  void removeHabit(Habit habit) {
    habits.remove(habit);
    notifyListeners();
  }

  void completeHabit(int id) {
    final habit = habits.firstWhere((h) => h.id == id);
    habit.completeHabit();
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    habits.where((h) => h.id == habit.id).first.updateHabit(habit);
    notifyListeners();
  }

  void updateHabitAmountCompleted(int id, int amountCompleted) {
    habits
        .where((h) => h.id == id)
        .first
        .updateHabitAmountCompleted(amountCompleted);
    notifyListeners();
  }
}
