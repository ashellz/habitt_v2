import 'package:flutter/widgets.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> updateLastOpenedDate(
  HabitProvider habitProvider,
  StateProvider stateProvider,
  StatsProvider statsProvider,
) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  DateTime lastOpenedDate;

  debugPrint("Running _updateLastOpenedDate");

  // I check if user has lastOpenedDate
  final temp = prefs.getString("lastOpenedDate");

  debugPrint("Last opened date: $temp");
  if (temp == null) {
    // If not, I set it to now
    lastOpenedDate = DateTime.now();
    final DateTime today = DateTime.now();
    debugPrint("Last opened date was null, setting it to: $today");
    prefs.setString("lastOpenedDate", today.toString());
  } else {
    // Else I set it to old one
    lastOpenedDate = DateTime.parse(temp);
    // I check for new day
    checkForNewDay(
      prefs,
      lastOpenedDate,
      habitProvider,
      stateProvider,
      statsProvider,
    );
  }
}

void checkForNewDay(
  SharedPreferences prefs,
  DateTime lastOpenedDate,
  HabitProvider habitProvider,
  StateProvider stateProvider,
  StatsProvider statsProvider,
) async {
  DateTime today = DateTime.now();

  if (lastOpenedDate.day != today.day ||
      lastOpenedDate.month != today.month ||
      lastOpenedDate.year != today.year) {
    debugPrint("New day, resetting completion");
    await habitProvider.saveHabitDay(lastOpenedDate);
    habitProvider.resetCompletion();
    await habitProvider.assignStreaks();
    statsProvider.perfectDaysStreak = statsProvider.refreshPerfectStreak();
    if (stateProvider.shouldUpdateStreaks) {
      stateProvider.shouldUpdateStreaks = false;
    }

    prefs.setString("lastOpenedDate", today.toString());
  }
}
