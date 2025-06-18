import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:hive_ce/hive.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> habits = [];
  final habitBox = Hive.box<Habit>('habits');
  final daysBox = Hive.box<Day>('days');

  HabitProvider({required this.statsProvider}) {
    init();
  }

  StatsProvider? statsProvider;

  Future<void> init() async {
    await _loadHabits();
    _fillToday();

    // Print out all days dates
    for (var day in daysBox.values) {
      debugPrint("Day: ${day.date}");
    }

    // Print out all habits
    for (var habit in habits) {
      debugPrint(
        "Habit: ${habit.name}, completed: ${habit.completed}, skipped: ${habit.skipped}",
      );
    }
  }

  Future<void> _loadHabits() async {
    habits = habitBox.values.toList();
  }

  void _fillToday() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final todayKey = today.toIso8601String().split('T').first;

    final todayEntry = daysBox.get(todayKey);

    if (todayEntry == null) {
      debugPrint("Creating new day entry");
      daysBox.put(todayKey, Day(date: today, habits: habits));
    }
  }

  Future<void> updateHabitInDB(Habit habit) async {
    if (statsProvider != null) {
      statsProvider!.shouldRefresh = true;
    }

    // Save the habit change
    await habit.save();

    // print out all habitbox habits and their skipped status

    for (var h in habitBox.values) {
      debugPrint("Habit: ${h.name}, skipped: ${h.skipped}");
    }

    // Save changes to current day in Day database
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final todayKey = today.toIso8601String().split('T').first;

    // Get today's day entry
    final day = daysBox.get(todayKey);

    if (day != null) {
      // Find and update the matching habit inside today's habit list
      final index = day.habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        day.habits[index] = habit;

        // Save the updated Day object
        await day.save();
      } else {
        debugPrint("Habit not found in day entry");

        // If habit is not found in day entry, add it
        day.habits.add(habit);
        await day.save();
      }
    } else {
      debugPrint("Day entry is null");

      // If day entry is null, create a new one
      saveHabitDay(today);
    }
  }

  void addHabit(Habit habit) {
    habits.add(habit);
    habitBox.add(habit);
    notifyListeners();
  }

  void removeHabit(Habit habit) async {
    habits.removeWhere((h) => h.id == habit.id);
    await habitBox.delete(habit.key);
    notifyListeners();
  }

  void completeHabit(int id) async {
    debugPrint("Completing habit: $id");
    final habit = habits.firstWhere((h) => h.id == id);
    await habit.completeHabit();
    updateHabitInDB(habit);
    notifyListeners();
  }

  void skipHabit(int id) async {
    debugPrint("Skipping habit: $id");
    final habit = habits.firstWhere((h) => h.id == id);
    await habit.skipHabit();
    updateHabitInDB(habit);
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    habits.where((h) => h.id == habit.id).first.updateHabit(habit);
    updateHabitInDB(habit);

    debugPrint("Updating habit: ${habit.name}");
    debugPrint("Habit: ${habit.name}, category id: ${habit.categoryId}");

    notifyListeners();
  }

  void resetCompletion() async {
    debugPrint("Resetting completion");
    for (final habit in habits) {
      await habit.resetCompletion();
      await updateHabitInDB(habit);
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

  Future<void> saveHabitDay(DateTime day) async {
    final daySimple = DateTime(day.year, day.month, day.day);
    final String dayKey = daySimple.toIso8601String().split('T').first;
    debugPrint("Saving day at: $daySimple");

    final clonedHabits = habits.map((h) => h.copy()).toList();

    daysBox.put(dayKey, Day(date: daySimple, habits: clonedHabits));
  }

  Future<void> assignStreaks() async {
    debugPrint("Assigning streaks");
    final sortedDays =
        daysBox.values.toList()..sort((a, b) => b.date.compareTo(a.date));

    // We now remove today from the list
    sortedDays.removeWhere((day) => day.date.day == DateTime.now().day);

    // We now have a list of days to work with
    // from today to the day we started using the app
    // day has a date and habits

    final currentHabits = habitBox.values;

    // We save all current habits from habitBox

    // We should now check every single habit from currentHabits
    // And for each habit we check every single day
    // from today to the day we started using the app or the day habit isnt completed

    for (final habit in currentHabits) {
      debugPrint("Checking habit: ${habit.name}");

      int streak = 0;
      int longestStreak = habit.longestStreak;

      bool shouldBreak = false;

      bool completed = false;
      bool skipped = false;

      for (final day in sortedDays) {
        debugPrint("Checking day: ${day.date} for habit: ${habit.name}");

        for (final dayHabit in day.habits) {
          if (dayHabit.id == habit.id) {
            completed = dayHabit.completed;
            skipped = dayHabit.skipped;

            debugPrint(
              "Completed: $completed, Skipped: $skipped, Streak: $streak on day ${day.date}",
            );

            if (completed) {
              if (!skipped) {
                streak++;
              }
            } else {
              shouldBreak = true;
              break;
            }

            if (streak > longestStreak) {
              longestStreak = streak;
            }
          }
        }

        if (shouldBreak) {
          break;
        }
      }

      habit.streak = streak;
      habit.longestStreak = longestStreak;

      debugPrint("Streak: $streak, Longest Streak: $longestStreak");

      habit.save();
    }
  }
}
