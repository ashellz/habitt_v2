import 'package:flutter/widgets.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/date_key.dart';
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

// lastOpenedDate is only written once the whole new-day routine has finished,
// so a second call while one is running (startup plus a resume, say after a
// system dialog) would still see the old date. It would then save the last
// opened day again from habits the first run already reset, wiping that day's
// progress, so overlapping calls are dropped.
bool _newDayCheckRunning = false;

void checkForNewDay(
  SharedPreferences prefs,
  DateTime lastOpenedDate,
  HabitProvider habitProvider,
  StateProvider stateProvider,
  StatsProvider statsProvider,
) {
  if (_newDayCheckRunning) {
    debugPrint("[NEWDAY] already running, skipping overlapping check");
    return;
  }
  _newDayCheckRunning = true;
  _checkForNewDay(
    prefs,
    lastOpenedDate,
    habitProvider,
    stateProvider,
    statsProvider,
  ).whenComplete(() => _newDayCheckRunning = false);
}

Future<void> _checkForNewDay(
  SharedPreferences prefs,
  DateTime lastOpenedDate,
  HabitProvider habitProvider,
  StateProvider stateProvider,
  StatsProvider statsProvider,
) async {
  DateTime today = DateTime.now();
  debugPrint(
    "[NEWDAY] check lastOpened=$lastOpenedDate now=$today "
    "habits=${habitProvider.habits.length}",
  );
  final crossedWeekBoundary = !_isSameWeek(lastOpenedDate, today);
  final crossedMonthBoundary =
      lastOpenedDate.month != today.month || lastOpenedDate.year != today.year;

  if (lastOpenedDate.day != today.day ||
      lastOpenedDate.month != today.month ||
      lastOpenedDate.year != today.year) {
    final normalizedLastOpened = DateTime(
      lastOpenedDate.year,
      lastOpenedDate.month,
      lastOpenedDate.day,
    );
    final normalizedToday = DateTime(today.year, today.month, today.day);

    // The device clock moved backwards (e.g. the user set the date a few days
    // ahead and then back). Today's real progress was already snapshotted when
    // the clock moved ahead, so restore it instead of resetting completion.
    // Days dated after today are ignored by the streak calculations.
    if (normalizedToday.isBefore(normalizedLastOpened)) {
      debugPrint("Clock moved backwards, restoring today's progress");
      await habitProvider.saveHabitDay(lastOpenedDate, isAutoCreated: true);
      await habitProvider.restoreTodayFromSnapshot();
      await habitProvider.assignStreaks();
      statsProvider.perfectDaysStreak = statsProvider.refreshPerfectStreak();
      if (stateProvider.shouldUpdateStreaks) {
        stateProvider.shouldUpdateStreaks = false;
      }
      prefs.setString("lastOpenedDate", today.toString());
      return;
    }

    debugPrint("New day, resetting completion");
    await habitProvider.saveHabitDay(lastOpenedDate, isAutoCreated: true);

    DateTime gapDay = addCalendarDays(lastOpenedDate, 1);
    while (gapDay.isBefore(normalizedToday)) {
      await habitProvider.saveHabitDay(
        gapDay,
        resetCompletion: true,
        isAutoCreated: true,
      );
      gapDay = addCalendarDays(gapDay, 1);
    }

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
  final monday = addCalendarDays(normalized, -(normalized.weekday - 1));
  final startOfYear = DateTime(monday.year, 1, 1);
  final dayOfYear = calendarDaysBetween(startOfYear, monday) + 1;
  return (monday.year * 1000) + dayOfYear;
}

bool _isSameWeek(DateTime a, DateTime b) {
  return _weekKey(a) == _weekKey(b);
}
