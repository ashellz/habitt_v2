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

  // the providers live as long as the app, so a sync that finds the new-day
  // check still due later on (app kept open past midnight) can run it itself
  NewDayGate._runner ??=
      () => updateLastOpenedDate(habitProvider, stateProvider, statsProvider);

  // I check if user has lastOpenedDate
  final temp = prefs.getString("lastOpenedDate");

  debugPrint("Last opened date: $temp");
  if (temp == null) {
    // If not, I set it to now
    lastOpenedDate = DateTime.now();
    final DateTime today = DateTime.now();
    debugPrint("Last opened date was null, setting it to: $today");
    await prefs.setString("lastOpenedDate", today.toString());
  } else {
    // Else I set it to old one
    lastOpenedDate = DateTime.parse(temp);
    // I check for new day
    await checkForNewDay(
      prefs,
      lastOpenedDate,
      habitProvider,
      stateProvider,
      statsProvider,
    );
  }
}

/// Keeps the new-day check and cloud syncs from running over each other.
class NewDayGate {
  NewDayGate._();

  static Future<void>? _check;
  static Future<void>? _sync;
  static Future<void> Function()? _runner;

  /// Called by a sync before it starts. False when the new-day check is due
  /// and couldn't run yet (the home page runs it, then syncs, on its own).
  static Future<bool> readyForSync() async {
    final running = _check;
    if (running != null) await running;
    if (!await _checkDue()) return true;
    final runner = _runner;
    if (runner == null) {
      debugPrint('[NEWDAY] sync deferred, new-day check not run yet');
      return false;
    }
    await runner();
    return !await _checkDue();
  }

  /// Marks [sync] as running until it completes.
  static void syncStarted(Future<void> sync) {
    _sync = sync;
    sync.whenComplete(() {
      if (identical(_sync, sync)) _sync = null;
    }).ignore();
  }

  static Future<bool> _checkDue() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('lastOpenedDate');
    if (stored == null) return false;
    final last = DateTime.tryParse(stored);
    if (last == null) return false;
    final now = DateTime.now();
    return last.year != now.year ||
        last.month != now.month ||
        last.day != now.day;
  }

  @visibleForTesting
  static void reset() {
    _check = null;
    _sync = null;
    _runner = null;
  }
}

// lastOpenedDate is only written once the whole new-day routine has finished,
// so a second call while one is running (startup plus a resume, say after a
// system dialog) would still see the old date. It would then save the last
// opened day again from habits the first run already reset, wiping that day's
// progress, so an overlapping call waits for the running one instead.
Future<void> checkForNewDay(
  SharedPreferences prefs,
  DateTime lastOpenedDate,
  HabitProvider habitProvider,
  StateProvider stateProvider,
  StatsProvider statsProvider,
) {
  final running = NewDayGate._check;
  if (running != null) {
    debugPrint("[NEWDAY] already running, waiting for it");
    return running;
  }
  late final Future<void> check;
  check = () async {
    final sync = NewDayGate._sync;
    if (sync != null) {
      debugPrint("[NEWDAY] waiting for the running sync");
      await sync.catchError((_) {});
    }
    await _checkForNewDay(
      prefs,
      lastOpenedDate,
      habitProvider,
      stateProvider,
      statsProvider,
    );
  }().whenComplete(() {
    if (identical(NewDayGate._check, check)) NewDayGate._check = null;
  });
  NewDayGate._check = check;
  return check;
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
      await prefs.setString("lastOpenedDate", today.toString());
      return;
    }

    debugPrint("New day, resetting completion");
    await habitProvider.saveHabitDay(lastOpenedDate, isAutoCreated: true);

    // Days the app wasn't opened on. One that already has a snapshot (synced in
    // from another device, or recorded already) is left alone: rewriting it
    // from today's live habits would wipe its completions and put in habits
    // as they are now, not as they were that day.
    DateTime gapDay = addCalendarDays(lastOpenedDate, 1);
    while (gapDay.isBefore(normalizedToday)) {
      if (!habitProvider.hasRecordedDay(gapDay)) {
        await habitProvider.saveHabitDay(
          gapDay,
          resetCompletion: true,
          isAutoCreated: true,
        );
      }
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

    await prefs.setString("lastOpenedDate", today.toString());
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
