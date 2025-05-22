import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> habits = [];
  final habitBox = Hive.box<Habit>('habits');
  final daysBox = Hive.box<Day>('days');

  HabitProvider() {
    init();
  }

  Future<void> init() async {
    await _loadHabits();
    _fillToday();
  }

  Future<void> _loadHabits() async {
    habits = habitBox.values.toList();
  }

  void _fillToday() {
    final today = DateTime.now();
    final todayKey = today.toIso8601String().split('T').first;

    final todayEntry = daysBox.get(todayKey);

    if (todayEntry == null) {
      debugPrint("Creating new day entry");
      daysBox.put(todayKey, Day(date: today, habits: habits));
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

  void resetCompletion() {
    for (final habit in habits) {
      habit.resetCompletion();
      updateHabitInDB(habit);
    }
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

  void saveHabitDay(DateTime day) {
    final DateTime daySimple = DateTime(day.year, day.month, day.day);

    daysBox.put(daySimple.toString(), Day(date: daySimple, habits: habits));
  }

  Future<void> assignStreaks() async {
    debugPrint("Assigning streaks");
    debugPrint("Daybox key: ${daysBox.keyAt(0)}");
    final sortedDays =
        daysBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));

    debugPrint("Sorted days: ${sortedDays.length}");

    final Map<int, int> currentStreaks = {};

    // Checks all days in database
    for (final day in sortedDays) {
      // If today, ignore
      if (day.date.day == DateTime.now().day &&
          day.date.month == DateTime.now().month &&
          day.date.year == DateTime.now().year) {
        continue;
      }

      debugPrint("Checking day ${day.date}");
      for (final habit in day.habits) {
        debugPrint("Checking ${habit.name}");
        final habitFromBox = habitBox.get(habit.id);
        if (habitFromBox == null) continue;

        if (!habit.completed) {
          debugPrint("Resetting streak for ${habit.name}");
          currentStreaks.remove(habit.id);
          habitFromBox.streak = 0;
        } else {
          debugPrint("Continuing streak for ${habit.name}");
          final previousStreak = currentStreaks[habit.id] ?? 0;
          debugPrint("Previous streak: $previousStreak");
          final newStreak = previousStreak + 1;
          debugPrint("New streak: $newStreak");
          currentStreaks[habit.id] = newStreak;
          debugPrint("Current streaks: $currentStreaks");
          habitFromBox.streak = newStreak;
          debugPrint("Habit from box: ${habitFromBox.streak}");
        }

        debugPrint("Saving ${habit.name}, streak: ${habit.streak}");
        await habitFromBox.save();
      }
    }
    notifyListeners();
  }
}
