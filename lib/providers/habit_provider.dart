import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/check_reorder_categories.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> habits = [];

  DateTime? _dateJoined;
  DateTime get dateJoined => _dateJoined ?? DateTime.now();
  final habitBox = Hive.box<Habit>('habits');
  final daysBox = Hive.box<Day>('days');

  StatsProvider? statsProvider;
  BackupProvider? backupProvider;

  HabitProvider({this.statsProvider}) {
    init();
  }

  // Method to be called by the ProxyProvider's update callback
  void updateDependencies(StatsProvider newStatsProvider) {
    // Only update and notify if the instance has actually changed
    if (statsProvider != newStatsProvider) {
      statsProvider = newStatsProvider;
      // Add any logic that needs to run when the dependency is updated.
      // For example, re-fetching habits that depend on stats.
      // Then, notify listeners that this provider's data has changed.
      notifyListeners();
    }
  }

  void attachBackupProvider(BackupProvider provider) {
    backupProvider = provider;
  }

  Future<void> init() async {
    await _loadHabits();
    _fillToday();
    _loadDateJoined();
  }

  Future<void> _loadDateJoined() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString('dateJoined');
    if (dateString != null) {
      _dateJoined = DateTime.parse(dateString);
    } else {
      _dateJoined = DateTime.now();
      prefs.setString("dateJoined", _dateJoined.toString());
    }
    notifyListeners();
  }

  Future<void> _loadHabits() async {
    habits = habitBox.values.toList();
    /*
    bool checkCategory(int category) {
      return category == 1 || category == 2 || category == 3 || category == 4;
    }

    // Deletes all habits which category isnt 1,2,3 or 4
    habits.removeWhere((habit) => !checkCategory(habit.categoryId));

    // Also delete all of those habits from the database
    for (final habit in habitBox.values) {
      if (!checkCategory(habit.categoryId)) {
        await habit.delete();
      }
    }

    // Also delete from the days database
    for (final day in daysBox.values) {
      day.habits.removeWhere((habit) => !checkCategory(habit.categoryId));
    }*/
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
      daysBox.put(
        todayKey,
        Day(date: today, habits: habits, timestamp: DateTime.now().toUtc()),
      );
    }
  }

  Future<void> updateHabitInDB(Habit habit, {DateTime? day}) async {
    if (statsProvider != null) {
      statsProvider!.addShouldRefresh(StatsType.habitsCompleted);
    }

    DateTime usedDay =
        day ??
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Trying to get the real, saved habit from habitBox using the ID
    final realHabit = habitBox.values.firstWhere(
      (h) => h.id == habit.id,
      orElse: () => habit, // fallback to current one if not found
    );

    // Only save if habit is in box (not a detached copy)
    if (realHabit.isInBox) {
      await realHabit.save();
    } else {
      debugPrint("Habit is not in a box, skipping save()");
    }

    // Schedule auto-sync after habit modification
    backupProvider?.scheduleAutoSync();

    final dayKey = usedDay.toIso8601String().split('T').first;
    final dayEntry = daysBox.get(dayKey);

    if (dayEntry != null) {
      final index = dayEntry.habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        dayEntry.habits[index] = habit; // still use passed-in habit copy
        await dayEntry.save();
      } else {
        debugPrint("Habit not found in day entry");
        dayEntry.habits.add(habit);
        await dayEntry.save();
      }
    } else {
      debugPrint("Day entry is null");
      saveHabitDay(usedDay);
    }
  }

  // Function used to get list of habits from a specific day from database
  List<Habit> getHabitsFromDay(DateTime day, {bool hydrateMissing = false}) {
    final dayKey = day.toIso8601String().split('T').first;
    Day? dayEntry = daysBox.get(dayKey);
    List<Habit> dayHabits = dayEntry?.habits ?? [];

    // Optionally hydrate missing days (only when explicitly requested)
    if (hydrateMissing &&
        dayHabits.isEmpty &&
        day.isBefore(DateTime.now()) &&
        (_dateJoined == null || day.isAfter(_dateJoined!))) {
      saveHabitDay(day, resetCompletion: true);
      dayEntry = daysBox.get(dayKey);
      dayHabits = dayEntry?.habits ?? [];
    }

    return dayHabits;
  }

  void addHabit(Habit habit) {
    if (statsProvider != null) {
      statsProvider!.addShouldRefresh(StatsType.highestAmountOfHabitsLastWeek);
    }

    habits.add(habit);
    habitBox.add(habit);
    updateHabitInDB(habit);

    notifyListeners();
  }

  void removeHabit(Habit habit, BuildContext context) async {
    if (statsProvider != null) {
      statsProvider!.addShouldRefresh(StatsType.highestAmountOfHabitsLastWeek);
    }

    habits.removeWhere((h) => h.id == habit.id);
    await habit.deleteHabit();
    if (context.mounted) checkReorderCategories(context, habit);

    updateHabitInDB(habit);
    notifyListeners();
  }

  void completeHabit(
    int id,
    BuildContext context,
    StateProvider stateProvider, {
    required DateTime day,
  }) async {
    late Habit habit;

    final today = DateTime.now();
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(day.year, day.month, day.day);

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      final List<Habit> dayHabits = getHabitsFromDay(day, hydrateMissing: true);
      habit = dayHabits.firstWhere((h) => h.id == id);
      if (!stateProvider.shouldUpdateStreaks) {
        stateProvider.shouldUpdateStreaks = true;
      }
    }

    debugPrint("Completing habit: $id, day: $day");
    await habit.completeHabit();
    debugPrint("Habit completed: ${habit.completed}");
    if (context.mounted && daySimple == todaySimple) {
      checkReorderCategories(context, habit);
    }

    updateHabitInDB(habit, day: day);
    notifyListeners();
  }

  void skipHabit(
    int id,
    BuildContext context,
    StateProvider stateProvider, {
    required DateTime day,
  }) async {
    debugPrint("Skipping habit: $id");
    late Habit habit;

    final today = DateTime.now();
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(day.year, day.month, day.day);

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      final List<Habit> dayHabits = getHabitsFromDay(day, hydrateMissing: true);
      habit = dayHabits.firstWhere((h) => h.id == id);
      if (!stateProvider.shouldUpdateStreaks) {
        stateProvider.shouldUpdateStreaks = true;
      }
    }

    await habit.skipHabit();
    if (context.mounted && daySimple == todaySimple) {
      checkReorderCategories(context, habit);
    }
    updateHabitInDB(habit, day: day);
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    habits.where((h) => h.id == habit.id).first.updateHabit(habit);
    updateHabitInDB(habit);

    notifyListeners();
  }

  void resetCompletion() async {
    for (final habit in habits) {
      await habit.resetCompletion();
      await updateHabitInDB(habit);
    }
    notifyListeners();
  }

  void updateHabitAmountCompleted(
    int id,
    int amountCompleted,
    BuildContext context, {
    required DateTime day,
  }) {
    late Habit habit;

    final today = DateTime.now();
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(day.year, day.month, day.day);

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      final List<Habit> dayHabits = getHabitsFromDay(day, hydrateMissing: true);
      habit = dayHabits.firstWhere((h) => h.id == id);
    }

    habit.updateHabitAmountCompleted(amountCompleted);
    if (context.mounted) checkReorderCategories(context, habit);

    updateHabitInDB(habits.firstWhere((h) => h.id == id));
    notifyListeners();
  }

  void updateHabitDurationCompleted(
    int id,
    int durationCompleted,
    BuildContext context, {
    required DateTime day,
  }) {
    late Habit habit;

    final today = DateTime.now();
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(day.year, day.month, day.day);

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      final List<Habit> dayHabits = getHabitsFromDay(day, hydrateMissing: true);
      habit = dayHabits.firstWhere((h) => h.id == id);
    }

    habit.updateHabitDurationCompleted(durationCompleted);

    if (context.mounted) checkReorderCategories(context, habit);

    updateHabitInDB(habits.firstWhere((h) => h.id == id));
    notifyListeners();
  }

  Future<void> saveHabitDay(
    DateTime day, {
    bool resetCompletion = false,
  }) async {
    final daySimple = DateTime(day.year, day.month, day.day);
    final String dayKey = daySimple.toIso8601String().split('T').first;
    debugPrint("Saving day at: $daySimple");

    late final List<Habit> clonedHabits;

    if (resetCompletion) {
      clonedHabits = habits.map((h) => h.copyResetCompletion()).toList();
    } else {
      clonedHabits = habits.map((h) => h.copy()).toList();
    }

    daysBox.put(
      dayKey,
      Day(
        date: daySimple,
        habits: clonedHabits,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> assignStreaks() async {
    debugPrint("Assigning streaks");
    final sortedDays = daysBox.values.toList();

    sortedDays.sort(
      (a, b) => (DateTime.now().difference(a.date).inDays).compareTo(
        DateTime.now().difference(b.date).inDays,
      ),
    );

    // We now remove today from the list
    sortedDays.removeWhere((day) => day.date.day == DateTime.now().day);

    // We now have a list of days to work with
    // from today to the day we started using the app
    // day has a date and habits

    // If the difference between last saved day and today is bigger then 1, then all streaks are 0
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // We start from the first one because that is the closest day to today
    if (sortedDays.first.date.difference(today).inDays > 1) {
      debugPrint("All habits are 0");
      for (final habit in habits) {
        habit.streak = 0;
        habit.save();
      }
      notifyListeners();
      return;
    }

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
              streak++;
            } else if (!skipped) {
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

      habit.updateStreak(streak: streak, longestStreak: longestStreak);
      debugPrint("Streak: $streak, Longest Streak: $longestStreak");

      habit.save();
    }

    // Trigger auto-sync after updating all streaks
    backupProvider?.scheduleAutoSync();
    notifyListeners();
  }
}
