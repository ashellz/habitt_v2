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
  final crossedWeekBoundary = !_isSameWeek(lastOpenedDate, today);
  final crossedMonthBoundary =
      lastOpenedDate.month != today.month || lastOpenedDate.year != today.year;

  if (lastOpenedDate.day != today.day ||
      lastOpenedDate.month != today.month ||
      lastOpenedDate.year != today.year) {
    debugPrint("New day, resetting completion");
    await habitProvider.saveHabitDay(lastOpenedDate, isAutoCreated: true);
    await habitProvider.resetCompletion();
    await habitProvider.resetScheduleCountersIfNeeded(
      resetWeekly: crossedWeekBoundary,
      resetMonthly: crossedMonthBoundary,
    );
    await habitProvider.assignStreaks();
    statsProvider.perfectDaysStreak = statsProvider.refreshPerfectStreak();
    if (stateProvider.shouldUpdateStreaks) {
      stateProvider.shouldUpdateStreaks = false;
    }

    prefs.setString("lastOpenedDate", today.toString());
  }
}

int _weekKey(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final monday = normalized.subtract(Duration(days: normalized.weekday - 1));
  final startOfYear = DateTime(monday.year, 1, 1);
  final dayOfYear = monday.difference(startOfYear).inDays + 1;
  return (monday.year * 1000) + dayOfYear;
}

bool _isSameWeek(DateTime a, DateTime b) {
  return _weekKey(a) == _weekKey(b);
}
