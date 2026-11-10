import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/services/completion_sound_player.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/util/check_reorder_categories.dart';
import 'package:habitt/util/custom_appearance.dart';
import 'package:habitt/util/date_key.dart';
import 'package:habitt/util/duration_seconds_migration.dart';
import 'package:habitt/util/health_override_notice.dart';
import 'package:habitt/util/health_value_guard.dart';
import 'package:habitt/util/optional_habit_order.dart';
import 'package:habitt/util/streak_moment.dart';
import 'package:habitt/util/premade_habit_type_migration.dart';
import 'package:provider/provider.dart';
import 'package:habitt/models/streak_health.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// See [HabitProvider.reminderStateSnapshot].
typedef HabitReminderState =
    ({bool completed, int weekCount, int monthCount, String definition});

class HabitProvider extends ChangeNotifier {
  List<Habit> habits = [];
  List<Habit> todaysHabits = [];

  DateTime? _dateJoined;
  DateTime get dateJoined => _dateJoined ?? DateTime.now();
  final habitBox = Hive.box<Habit>('habits');
  final daysBox = Hive.box<Day>('days');

  // called when a habit is deleted or paused
  // so an active timer session for it can be cleared
  void Function(int habitId)? onHabitDeactivated;
  DateTime? selectedDate;
  int dataVersion = 0;

  // true after provider has initialized
  // used to avoid draining deferred completions (from notifications)
  // before habits list is populated
  bool get isInitialized => dataVersion > 0;

  int streakEntryEpoch = 0;
  int streakExitEpoch = 0;

  // Habit health stuff

  final Map<int, int> _habitConsecutiveMisses = {};

  int consecutiveMissesFor(int habitId) =>
      _habitConsecutiveMisses[habitId] ?? 0;

  StreakHealth streakHealthFor(Habit habit) {
    final today = _normalizeDate(DateTime.now());
    if (!_appearsOnDay(habit, today)) return StreakHealth.healthy;

    return resolveStreakHealth(
      streak: habit.streak,
      tailMisses: consecutiveMissesFor(habit.id),
      todayIsSecure: habit.completed,
    );
  }

  void setSelectedDate(DateTime date) {
    final now = DateTime.now();
    final previousDate = selectedDate ?? now;
    final previousWasToday =
        previousDate.year == now.year &&
        previousDate.month == now.month &&
        previousDate.day == now.day;
    final nextIsToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    selectedDate = date;
    // Only animate on an actual transition. Re-selecting today while already on
    // today must not replay the entrance animation.
    if (nextIsToday && !previousWasToday) {
      streakEntryEpoch++;
    } else if (!nextIsToday && previousWasToday) {
      streakExitEpoch++;
    }
    notifyListeners();
  }

  void clearSelectedDate() {
    selectedDate = null;
    notifyListeners();
  }

  StatsProvider? statsProvider;
  HabitStatsProvider? habitStatsProvider;
  BackupProvider? backupProvider;
  NotificationsProvider? notificationsProvider;

  HabitProvider({this.statsProvider}) {
    init(animateStreakEntry: true);
  }

  final Completer<void> _firstLoad = Completer<void>();

  /// Completes once the first [init] has loaded the habits and [dateJoined].
  /// The constructor starts it without waiting, so anything that needs those
  /// values at launch awaits this.
  Future<void> get firstLoadDone => _firstLoad.future;

  // Method to be called by the ProxyProvider's update callback
  void updateDependencies(StatsProvider newStatsProvider) {
    // Give StatsProvider a back-reference so it can schedule-filter day
    // snapshots (see habitsCountingForDay). Stable across rebuilds; safe to set
    // every update.
    newStatsProvider.attachHabitProvider(this);
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

  void attachNotificationsProvider(NotificationsProvider provider) {
    notificationsProvider = provider;
  }

  void attachHabitStatsProvider(HabitStatsProvider provider) {
    habitStatsProvider = provider;
  }

  Future<void> init({bool animateStreakEntry = false}) async {
    // one time conversion from minutes to seconds for older versions
    final prefs = await SharedPreferences.getInstance();
    await migrateDurationToSeconds(
      habitBox: habitBox,
      daysBox: daysBox,
      prefs: prefs,
    );

    // one time migration of the removed Running/Walk/Gym premade types
    // into their Workouts-section equivalents
    await migratePremadeWorkoutTypes(
      habitBox: habitBox,
      daysBox: daysBox,
      prefs: prefs,
    );

    // one time repair of custom-interval schedules that the old DST-unsafe
    // builders shifted a day early after an autumn clock change
    await migrateDstShiftedCustomAppearance(habitBox: habitBox, prefs: prefs);

    await _loadHabits();
    await _seedDeletedAtTimestamps();
    await _purgeExpiredDeletedHabits();
    refreshTodaysHabits(notify: false);
    await _loadDateJoined();
    await _loadMissingDays();
    _fillToday();
    await _sanitizeDaySnapshots();
    await _slimDaySnapshots();
    _syncAllHabitNotifications();
    dataVersion++;
    if (animateStreakEntry) streakEntryEpoch++;
    notifyListeners();
    if (!_firstLoad.isCompleted) _firstLoad.complete();
  }

  /// What a sync needs after each merge it applies, instead of a full [init]
  /// per delta file (that walks every day since joining and reruns the
  /// startup repairs): the habit list (so habits the merge added are in it,
  /// for the reminder resync) and today's list, and a redraw. Not deferring
  /// the redraw too: a screen left stale for the whole sync invites a tap on a
  /// habit the merge already completed, which would toggle it back off. The
  /// sync runs [init] once when its merges are done.
  void reloadAfterMerge() {
    habits = habitBox.values.toList();
    _sortHabitsByCategoryAndOrder(habits);
    refreshTodaysHabits(notify: false);
    dataVersion++;
    notifyListeners();
  }

  static const String _daySnapshotSanitizedKey = 'daySnapshotsSanitized_v1';
  static const String _daySnapshotsSlimmedKey = 'daySnapshotsSlimmed_v1';

  // One time: day snapshots written before Habit.forDay dropped the habit's
  // own details (reminders, translated names, streaks, their
  // timestamps) still hold full copies. Strip them in place. The day's
  // timestamp and isAutoCreated stay as they are, so nothing is re-uploaded
  // and the merge rules don't change: each device slims its own days, and
  // the next full backup is written slim.
  Future<void> _slimDaySnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_daySnapshotsSlimmedKey) ?? false) return;

    var slimmed = 0;
    for (final key in daysBox.keys.toList()) {
      final day = daysBox.get(key);
      if (day == null || !day.habits.any((h) => h.hasHabitOnlyFields)) {
        continue;
      }
      await daysBox.put(
        key,
        Day(
          date: day.date,
          habits: [for (final h in day.habits) h.forDay()],
          timestamp: day.timestamp,
          isAutoCreated: day.isAutoCreated,
        ),
      );
      slimmed++;
    }
    // reclaim the space the full copies took
    if (slimmed > 0) await daysBox.compact();
    debugPrint('[SLIM] slimmed $slimmed day snapshots');

    await prefs.setBool(_daySnapshotsSlimmedKey, true);
  }

  Future<void> _sanitizeDaySnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_daySnapshotSanitizedKey) ?? false) {
      return;
    }

    final today = _normalizeDate(DateTime.now());
    final keys = daysBox.keys.toList();
    for (final key in keys) {
      final day = daysBox.get(key);
      if (day == null) continue;

      // Leave today untouched — it tracks the live habit set, not a snapshot.
      if (_normalizeDate(day.date) == today) continue;

      final filtered = _scheduledHabitsForDaySnapshot(day.date, day.habits);
      if (filtered.length == day.habits.length) continue; // already clean

      await daysBox.put(
        key,
        Day(
          date: day.date,
          habits: [for (final h in filtered) h.forDay()],
          timestamp: day.timestamp,
          isAutoCreated: day.isAutoCreated,
        ),
      );
    }

    await prefs.setBool(_daySnapshotSanitizedKey, true);
  }

  Future<void> _syncAllHabitNotifications({bool force = false}) async {
    // runs through all habits and schedules notifications for each habit properly
    final notificationsEnabled =
        notificationsProvider?.areHabitNotificationsEnabled ?? true;
    if (!notificationsEnabled) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final today =
        _normalizeDate(DateTime.now()).toIso8601String().split('T').first;

    if (!force) {
      final lastSync = prefs.getString('lastNotificationSyncDate');
      if (lastSync == today) {
        debugPrint('Notification sync skipped — already synced today');
        return;
      }
    }

    await NotificationService.scheduleAllHabitNotifications(
      habits: habits.where(
        (habit) => habit.isDeleted != true && habit.isPaused != true,
      ),
      appearsOnDay: appearsOnDay,
    );

    await prefs.setString('lastNotificationSyncDate', today);
  }

  Future<void> syncSingleHabitNotifications(Habit habit) async {
    final notificationsEnabled =
        notificationsProvider?.areHabitNotificationsEnabled ?? true;

    if (!notificationsEnabled) {
      return;
    }

    await NotificationService.rescheduleHabitNotifications(
      habit: habit,
      appearsOnDay: appearsOnDay,
    );
  }

  /// What a sync merge can change about each habit's reminders: today's
  /// completion, the weekly/monthly progress that decides which days a target
  /// habit still shows up on, and its reminder definition (slots, schedule,
  /// pause/delete, ... see [NotificationService.reminderDefinitionKey]).
  /// Taken before the merge, handed to [resyncRemindersAfterMerge] after it.
  Map<int, HabitReminderState> reminderStateSnapshot() {
    final today = _normalizeDate(DateTime.now());
    return {
      for (final habit in habits) habit.id: _reminderState(habit, today),
    };
  }

  HabitReminderState _reminderState(Habit habit, DateTime today) => (
    completed: habit.completed,
    weekCount: _effectiveTimesCompletedThisWeek(habit, today),
    monthCount: _effectiveTimesCompletedThisMonth(habit, today),
    definition: NotificationService.reminderDefinitionKey(habit),
  );

  /// A completion that arrives through sync never goes through the local
  /// completion paths, and the merge's init() skips the daily notification
  /// sync once it already ran today, so reminders would keep firing for a
  /// habit the other device completed. Runs the same reminder update a local
  /// completion does for every habit whose state [before] the merge differs.
  ///
  /// Definition changes from the other device (a new habit, moved or removed
  /// reminder times, a schedule edit, a pause or delete) instead get one full
  /// forced resync: it wipes every pending habit reminder, so slots that no
  /// longer exist and habits that are now paused/deleted stop firing, then
  /// schedules all habits from their merged state. That also covers any
  /// completion change in the same merge (today's slots of habits completed
  /// today are never scheduled), so the per-habit pass is skipped. Merges
  /// that change no definition don't pay for a full reschedule.
  Future<void> resyncRemindersAfterMerge(
    Map<int, HabitReminderState> before,
  ) async {
    final today = _normalizeDate(DateTime.now());
    final definitionChanged = NotificationService.reminderDefinitionsChanged(
      {for (final entry in before.entries) entry.key: entry.value.definition},
      {
        for (final habit in habits)
          habit.id: NotificationService.reminderDefinitionKey(habit),
      },
    );
    if (definitionChanged) {
      await _syncAllHabitNotifications(force: true);
      return;
    }

    for (final habit in habits) {
      final previous = before[habit.id];
      if (previous == null) continue;
      final current = _reminderState(habit, today);

      if (previous.completed != current.completed) {
        // also covers weekly/monthly: the merged period counters are already
        // on the habit, so its reschedule sees the other device's progress
        await _syncNotificationsOnCompletionChange(
          habit: habit,
          wasCompleted: previous.completed,
          isNowCompleted: current.completed,
          daySimple: today,
          todaySimple: today,
        );
      } else if ((habit.scheduleType == ScheduleType.weekly &&
              previous.weekCount != current.weekCount) ||
          (habit.scheduleType == ScheduleType.monthly &&
              previous.monthCount != current.monthCount)) {
        // a past day of the current week/month was completed elsewhere: the
        // days the habit still has to show up on this period moved
        await syncSingleHabitNotifications(habit);
      }
    }
  }

  Future<void> _syncNotificationsOnCompletionChange({
    required Habit habit,
    required bool wasCompleted,
    required bool isNowCompleted,
    required DateTime daySimple,
    required DateTime todaySimple,
  }) async {
    if (wasCompleted == isNowCompleted) return;

    // dismiss/cancel that day's notification whenever a habit becomes completed
    if (isNowCompleted) {
      await NotificationService.cancelHabitNotificationsForDay(
        habit,
        daySimple,
      );
    }

    if (daySimple == todaySimple) {
      if (isNowCompleted) {
        // Daily: future schedule doesn't change, and today's slots were already
        // cancelled above, no need to handle anything here

        // Weekly/monthly/custom: completing today may satisfy the period target,
        // therefore already scheduled notifications for other days may be inapropriate
        // so recalculation is needed to know which future days still need notifications
        if (habit.scheduleType != ScheduleType.daily) {
          await NotificationService.rescheduleHabitNotifications(
            habit: habit,
            appearsOnDay: appearsOnDay,
            skipToday: true,
          );
        }
      } else {
        // if uncompleted - restore notifications for today and future days
        await syncSingleHabitNotifications(habit);
      }
    } else {
      // Past day completion change: only weekly/monthly habits within the current period (week/month)
      // need a reschedule, because toggling changes timesCompletedThisWeek/Month which
      // affects appearsOnDay for remaining days in that period
      final affectsCurrentPeriod =
          (habit.scheduleType == ScheduleType.weekly &&
              _isSameWeek(daySimple, todaySimple)) ||
          (habit.scheduleType == ScheduleType.monthly &&
              _isSameMonth(daySimple, todaySimple));
      if (affectsCurrentPeriod) {
        await syncSingleHabitNotifications(habit);
      }
      // Daily/custom past-day toggle: no effect on future notifications,
      // skipped. (A "show if missed" restart from a past day does move the
      // schedule, updateHabitInDB resyncs its reminders when that happens.)
    }
  }

  Future<void> _loadMissingDays() async {
    if (_dateJoined == null) {
      debugPrint("Date joined is null");
      return;
    }

    final today = _normalizeDate(DateTime.now());
    final normalizedDateJoined = _normalizeDate(_dateJoined!);

    // Iterate through each day from dateJoined to today
    DateTime currentDay = normalizedDateJoined;

    while (!currentDay.isAfter(today)) {
      final dayKey = currentDay.toIso8601String().split('T').first;

      // Check if this day already exists in the database
      if (daysBox.get(dayKey) == null) {
        // Save the day with habits that should be scheduled for that day
        await saveHabitDay(
          currentDay,
          resetCompletion: true,
          isAutoCreated: true,
        );
      }

      // Move to the next day
      currentDay = addCalendarDays(currentDay, 1);
    }
  }

  Future<void> _loadDateJoined() async {
    final prefs = await SharedPreferences.getInstance();

    // Check daysBox for the earliest day with habits
    final allDays = daysBox.values.toList();
    final daysWithHabits =
        allDays.where((day) => day.habits.isNotEmpty).toList();
    daysWithHabits.sort((a, b) => a.date.compareTo(b.date));

    if (daysWithHabits.isNotEmpty) {
      // Earliest day with habits is the dateJoined
      _dateJoined = _normalizeDate(daysWithHabits.first.date);
      debugPrint("Date joined set from daysBox: $_dateJoined");
      // Update SharedPreferences with the correct date
      prefs.setString("dateJoined", _dateJoined!.toIso8601String());
    } else {
      // No days with habits, fall back to SharedPreferences or today
      final dateString = prefs.getString('dateJoined');
      if (dateString != null) {
        _dateJoined = _normalizeDate(DateTime.parse(dateString));
        debugPrint("Date joined set from SharedPreferences: $_dateJoined");
      } else {
        _dateJoined = _normalizeDate(DateTime.now());
        debugPrint("Date joined set to today: $_dateJoined");
        prefs.setString("dateJoined", _dateJoined!.toIso8601String());
      }
    }

    notifyListeners();
  }

  Future<void> importDateJoined(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    if (_dateJoined == null || date.isBefore(_dateJoined!)) {
      _dateJoined = date;
      prefs.setString("dateJoined", _dateJoined.toString());
    }

    notifyListeners();
  }

  Future<void> _loadHabits() async {
    habits = habitBox.values.toList();
    await _normalizeHabitOrders();
    _sortHabitsByCategoryAndOrder(habits);
    await _repairHabitCreatedAt();
    await _seedPauseHistory();
  }

  static const String _deletedAtSeededKey = 'deletedAtSeeded_v1';

  // one time function for old deleted habits with no
  // deletedAt timestamp to be given a deletedAt timestamp
  Future<void> _seedDeletedAtTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_deletedAtSeededKey) ?? false) {
      return;
    }

    for (final habit in habits) {
      if (habit.isDeleted == true && habit.deletedAt == null) {
        habit.deletedAt =
            habit.timestamps['isDeleted'] ?? DateTime.now().toUtc();
        if (habit.isInBox) {
          await habit.save();
        }
      }
    }

    await prefs.setBool(_deletedAtSeededKey, true);
  }

  // habits stay in trash for 30 days before purging completely
  static const int deletedHabitPurgeDays = 30;

  // delete habits older than 30 days
  Future<void> _purgeExpiredDeletedHabits() async {
    final now = DateTime.now().toUtc();
    final expired =
        habits.where((habit) {
          if (habit.isDeleted != true) return false;
          final deletedAt = habit.deletedAt;
          if (deletedAt == null) return false;
          return now.difference(deletedAt).inDays >= deletedHabitPurgeDays;
        }).toList();

    if (expired.isEmpty) return;

    for (final habit in expired) {
      habitStatsProvider?.removeHabit(habit.id);
      habits.remove(habit);
      if (habit.isInBox) {
        await habit.delete();
      }
    }
  }

  // old createdAt was moving backward to the actual dateJoined, this fixes it by id
  Future<void> _repairHabitCreatedAt() async {
    final now = DateTime.now().toUtc();
    final firstProgress = <int, DateTime>{};
    for (final day in daysBox.values) {
      final dayDate = _normalizeDate(day.date);
      for (final h in day.habits) {
        if (!h.hasAnyProgress()) continue;
        final current = firstProgress[h.id];
        if (current == null || dayDate.isBefore(current)) {
          firstProgress[h.id] = dayDate;
        }
      }
    }

    for (final habit in habits) {
      final created = _normalizeDate(habit.createdAt.toLocal());
      final progressDay = firstProgress[habit.id];
      DateTime? repaired;

      final idTime = _creationTimeFromId(habit.id);
      if (idTime != null) {
        final idDay = _normalizeDate(idTime.toLocal());
        final loggedBefore = progressDay != null && progressDay.isBefore(idDay);
        if (created.isBefore(idDay) && !loggedBefore) repaired = idTime;
      }
      if (repaired == null &&
          progressDay != null &&
          progressDay.isBefore(created)) {
        repaired = progressDay.toUtc();
      }
      if (repaired == null) continue;

      debugPrint(
        '[CREATED] habit ${habit.id}: createdAt ${habit.createdAt} -> $repaired',
      );
      habit.createdAt = repaired.toUtc();
      habit.timestamps['createdAt'] = now;
      if (habit.isInBox) await habit.save();
    }
  }

  // getting time created from habit id
  // used for fixing createdAt
  static DateTime? _creationTimeFromId(int id) {
    if (id <= 0) return null;
    final time = DateTime.fromMicrosecondsSinceEpoch(id, isUtc: true);
    if (time.isBefore(DateTime.utc(2020))) return null;
    if (time.isAfter(DateTime.now().toUtc().add(const Duration(days: 1)))) {
      return null;
    }
    return time;
  }

  static const String _pauseHistorySeededKey = 'pauseHistorySeeded_v1';

  // one time seeding pause history for habits that paused and unpaused before the logging feature was built
  Future<void> _seedPauseHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_pauseHistorySeededKey) ?? false) return;

    final now = DateTime.now().toUtc();
    for (final habit in habits) {
      if (habit.isPaused == true || habit.pausedRanges.isNotEmpty) continue;
      final unpausedAt = habit.timestamps['isPaused'];
      if (unpausedAt == null) continue;
      final unpausedDay = _normalizeDate(unpausedAt.toLocal());
      final createdDay = _normalizeDate(habit.createdAt.toLocal());

      DateTime? pauseStart;
      var day = addCalendarDays(unpausedDay, -1);
      for (var i = 0; i < 730 && !day.isBefore(createdDay); i++) {
        final record = daysBox.get(_dayKeyOf(day));
        if (record != null && record.habits.isNotEmpty) {
          Habit? copy;
          for (final h in record.habits) {
            if (h.id == habit.id) {
              copy = h;
              break;
            }
          }
          if (copy != null && copy.hasAnyProgress()) break;
          if (copy == null && _isScheduledOnDay(habit, day)) pauseStart = day;
        }
        day = addCalendarDays(day, -1);
      }
      if (pauseStart == null) continue;

      debugPrint(
        '[PAUSE] habit ${habit.id}: seeded stretch $pauseStart -> $unpausedAt',
      );
      habit.pausedRanges = Habit.unionPauseRanges(habit.pausedRanges, [
        pauseStart.toUtc(),
        unpausedAt,
      ]);
      habit.timestamps['pausedRanges'] = now;
      if (habit.isInBox) await habit.save();
    }

    await prefs.setBool(_pauseHistorySeededKey, true);
  }

  // Normalizing a datetime to be shorter so they can compare and be the same
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Function to check what week a date is in
  int _weekKey(DateTime date) {
    final normalized = _normalizeDate(date);
    final monday = addCalendarDays(normalized, -(normalized.weekday - 1));
    final startOfYear = DateTime(monday.year, 1, 1);
    final dayOfYear = calendarDaysBetween(startOfYear, monday) + 1;
    return (monday.year * 1000) + dayOfYear;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    return _weekKey(a) == _weekKey(b);
  }

  // Checks how many times a habit has been completed in the current week
  // Used for deterining if a habit with weekly schedule appears on a day
  int _effectiveTimesCompletedThisWeek(Habit habit, DateTime day) {
    final ts = habit.timestamps['timesCompletedThisWeek'];
    if (ts == null) return 0;
    // Convert UTC timestamp to local before comparing week keys, since `day`
    // uses local date components. Without this, late-night completions for
    // users behind UTC are attributed to the following week.
    return _weekKey(ts.toLocal()) == _weekKey(day)
        ? habit.timesCompletedThisWeek
        : 0;
  }

  // Checks how many times a habit has been completed in the current month
  // Used for deterining if a habit with monthly schedule appears on a day
  int _effectiveTimesCompletedThisMonth(Habit habit, DateTime day) {
    final ts = habit.timestamps['timesCompletedThisMonth'];
    if (ts == null) return 0;
    return _isSameMonth(ts.toLocal(), day) ? habit.timesCompletedThisMonth : 0;
  }

  int _daysLeftInWeek(DateTime day) => 8 - day.weekday;

  int _daysLeftInMonth(DateTime day) {
    final daysInMonth = DateTime(day.year, day.month + 1, 0).day;
    return daysInMonth - day.day + 1;
  }

  bool _isCriticalWeekDay(Habit progressSource, DateTime day, int target) {
    final owed = target - _effectiveTimesCompletedThisWeek(progressSource, day);
    if (owed <= 0) return false;
    return owed >= _daysLeftInWeek(day);
  }

  bool _isCriticalMonthDay(Habit progressSource, DateTime day, int target) {
    final owed =
        target - _effectiveTimesCompletedThisMonth(progressSource, day);
    if (owed <= 0) return false;
    return owed >= _daysLeftInMonth(day);
  }

  // Used for building the dates when habit should appear for a habit with custom schedule
  List<String> _buildCustomAppearance({
    required DateTime anchor,
    required int intervalDays,
  }) {
    // Starting from the anchor date, a full year of appearances. Calendar
    // arithmetic, so a DST fall-back day can't shift later dates a day early.
    return buildCustomAppearance(anchor: anchor, intervalDays: intervalDays);
  }

  // How far back a custom schedule keeps past dates when it gets extended.
  // Past days normally read their own day snapshot; this only covers the
  // live-list fallbacks (show-if-missed lookback, snapshots without a list).
  static const int _customAppearanceKeepPastDays = 365;

  // Ensures that a habit with custom schedule has its customAppearance list updated with future dates if needed
  void _ensureCustomAppearance(Habit habit, DateTime day) {
    final normalizedDay = _normalizeDate(day);

    if (habit.customAppearance.isNotEmpty) {
      final latest = DateTime.tryParse(habit.customAppearance.last);
      // If the latest scheduled appearance is after the day we are checking, then we dont need to update the schedule appearances yet
      if (latest != null && !normalizedDay.isAfter(latest)) {
        return;
      }
    }

    // Continue the existing grid from its last date, so extending never moves
    // the schedule. Only a habit with no list at all starts a fresh grid: from
    // the local day of its last update, or from the day being checked.
    final lastUpdate = habit.lastCustomUpdate;
    final today = _normalizeDate(DateTime.now());
    final earliest = normalizedDay.isBefore(today) ? normalizedDay : today;
    habit.customAppearance = extendCustomAppearance(
      dates: habit.customAppearance,
      intervalDays: habit.customIntervalDays,
      through: normalizedDay,
      fallbackAnchor: lastUpdate == null ? normalizedDay : lastUpdate.toLocal(),
      keepFrom: addCalendarDays(earliest, -_customAppearanceKeepPastDays),
    );

    final now = DateTime.now().toUtc();
    habit.lastCustomUpdate = now;
    habit.timestamps['customAppearance'] = now;
    habit.timestamps['lastCustomUpdate'] = now;
  }

  // Here we check if a habit's schedule (daily/weekly/monthly/custom) puts it
  // on a given day. Deliberately ignores isDeleted — a deleted habit keeps
  // "appearing" on its schedule so a restored habit's streak reflects the
  // days it missed while gone, same as any other miss (see assignStreaks).
  // Visibility (hiding deleted/paused habits from the UI) is a separate
  // concern, handled by _filteredHabitsForDay.
  bool _appearsOnDay(Habit habit, DateTime day, {Habit? progressHabit}) {
    if (habit.isPaused == true) {
      return false;
    }
    if (_isScheduledOnDay(habit, day, progressHabit: progressHabit)) {
      return true;
    }
    return _isMissedCarryOverDay(habit, day);
  }

  // How far back we look for the last scheduled day when carrying a miss over.
  // Covers the longest interval a user can pick (custom: 30 days, monthly: 31).
  static const int _missedCarryOverLookbackDays = 62;

  // "Show if missed" toggle (custom interval habits only; weekly/monthly
  // habits already stay visible until their target is reached): a custom habit
  // that was scheduled on an earlier day and not completed since keeps
  // appearing every day until it is completed (see _syncCustomRestartForDay
  // for what happens then). Only ever applies to today — past days keep their
  // recorded snapshot, whose schedule never lists a carry-over day, so a
  // carry-over day can never add a miss to the streak, only a bonus
  // completion. A missed carry-over day is listed under "Other habits" on that
  // past day (otherHabitsForDay), so it can still be ticked late.
  bool _isMissedCarryOverDay(Habit habit, DateTime day) {
    if (!habit.showIfMissed || habit.scheduleType != ScheduleType.custom) {
      return false;
    }

    final today = _normalizeDate(DateTime.now());
    if (_normalizeDate(day) != today) return false;
    return _isCarryOverDay(habit, today);
  }

  // Whether [day] falls in a carry-over stretch: the habit's last scheduled
  // day before it was missed and nothing was completed from then until the
  // day before [day].
  bool _isCarryOverDay(Habit habit, DateTime day) {
    final target = _normalizeDate(day);
    final createdDay = _normalizeDate(habit.createdAt.toLocal());
    DateTime? lastScheduled;
    for (var i = 1; i <= _missedCarryOverLookbackDays; i++) {
      final candidate = DateTime(target.year, target.month, target.day - i);
      if (candidate.isBefore(createdDay)) return false;
      if (_isScheduledOnDay(habit, candidate)) {
        lastScheduled = candidate;
        break;
      }
    }
    if (lastScheduled == null) return false;

    // Any completion from that scheduled day up to the day before settles it.
    for (
      var d = lastScheduled;
      d.isBefore(target);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      if (_completedOnDay(habit.id, d)) return false;
    }
    return true;
  }

  // Whether the habit is recorded as completed on [day]: the live habit for
  // today, the day snapshot for any other day.
  bool _completedOnDay(int habitId, DateTime day) {
    final normalized = _normalizeDate(day);
    if (normalized == _normalizeDate(DateTime.now())) {
      for (final h in habits) {
        if (h.id == habitId) return h.completed;
      }
      return false;
    }
    final snapshot = daysBox.get(_dayKeyOf(normalized));
    if (snapshot == null) return false;
    for (final recorded in snapshot.habits) {
      if (recorded.id == habitId) return recorded.completed;
    }
    return false;
  }

  // Whether the habit was completed on any day after [day], up to and
  // including today.
  bool _completedAfter(int habitId, DateTime day) {
    final today = _normalizeDate(DateTime.now());
    var d = _normalizeDate(day);
    while (d.isBefore(today)) {
      d = DateTime(d.year, d.month, d.day + 1);
      if (_completedOnDay(habitId, d)) return true;
    }
    return false;
  }

  String _dayKeyOf(DateTime day) =>
      _normalizeDate(day).toIso8601String().split('T').first;

  // Midday of [day] in UTC, so lastCustomUpdate (an anchor read back through
  // _normalizeDate) names that calendar day in any time zone.
  DateTime _anchorStamp(DateTime day) =>
      DateTime(day.year, day.month, day.day, 12).toUtc();

  // Keeps a "show if missed" custom habit's interval in step with a completion
  // change on [day] (today or a past day). Mutates [habit], which must be the
  // live habit, never a day snapshot copy: snapshots keep the schedule they
  // were recorded with so past streaks don't move. Returns whether the
  // schedule changed.
  //
  // Completed on a day it wasn't scheduled (a carry-over day, or an extra
  // completion from the details page or "Other habits"): the interval restarts
  // from that day, "every 3 days" means the next occurrence is 3 days after
  // that completion. Dates before the completion day are kept. Only for
  // habits with "show if missed" ticked, every other habit keeps its grid.
  //
  // Unticked again: the restart is undone. A restart is the only thing that
  // leaves two kept dates closer together than the interval (editing the
  // schedule and _ensureCustomAppearance rebuild the list without keeping
  // earlier dates), so [day] being less than an interval after the date
  // before it means it was a restart point, and the old grid is rebuilt from
  // that earlier date. Without this, unticking left [day] scheduled (so it
  // counted as a miss) and the interval shifted.
  //
  // Both are skipped when the habit was completed on a later day, so a later
  // restart is never overwritten by editing an older day.
  bool _syncCustomRestartForDay(
    Habit habit,
    DateTime day, {
    required bool completedOnDay,
  }) {
    if (!habit.showIfMissed || habit.scheduleType != ScheduleType.custom) {
      return false;
    }
    final target = _normalizeDate(day);
    final today = _normalizeDate(DateTime.now());
    if (target.isAfter(today)) return false;
    if (_completedAfter(habit.id, target)) return false;

    final key = _dayKeyOf(target);
    final interval = habit.customIntervalDays.clamp(1, 365);
    final now = DateTime.now().toUtc();

    if (completedOnDay) {
      if (habit.customAppearance.contains(key)) return false; // on schedule
      habit.customAppearance = [
        ...habit.customAppearance.where((d) => d.compareTo(key) < 0),
        ..._buildCustomAppearance(anchor: target, intervalDays: interval),
      ];
      habit.lastCustomUpdate = target == today ? now : _anchorStamp(target);
    } else {
      if (!habit.customAppearance.contains(key)) return false;
      final earlier =
          habit.customAppearance.where((d) => d.compareTo(key) < 0).toList()
            ..sort();
      if (earlier.isEmpty) return false;
      final previous = DateTime.tryParse(earlier.last);
      if (previous == null) return false;
      final gap =
          DateTime.utc(target.year, target.month, target.day)
              .difference(
                DateTime.utc(previous.year, previous.month, previous.day),
              )
              .inDays;
      if (gap >= interval) return false; // a regular scheduled day
      habit.customAppearance = [
        ...earlier.where((d) => d.compareTo(earlier.last) < 0),
        ..._buildCustomAppearance(anchor: previous, intervalDays: interval),
      ];
      habit.lastCustomUpdate = _anchorStamp(previous);
    }
    habit.timestamps['customAppearance'] = now;
    habit.timestamps['lastCustomUpdate'] = now;
    return true;
  }

  // After a past-day completion moved the live schedule, today's snapshot
  // still holds the schedule from this morning. Bring its copy in line so a
  // day the habit no longer shows on isn't recorded as a miss (and the
  // other way round).
  Future<void> _syncTodaySnapshotSchedule(Habit habit) async {
    final today = _normalizeDate(DateTime.now());
    final key = _dayKeyOf(today);
    final entry = daysBox.get(key);
    if (entry == null) return;
    final index = entry.habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      final recorded = entry.habits[index];
      if (identical(recorded, habit)) return;
      recorded.customAppearance = List<String>.from(habit.customAppearance);
      recorded.lastCustomUpdate = habit.lastCustomUpdate;
    } else if (_appearsOnDay(habit, today)) {
      entry.habits.add(habit.forDay());
    } else {
      return;
    }
    await daysBox.put(
      key,
      Day(
        date: entry.date,
        habits: [for (final h in entry.habits) h.forDay()],
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  bool _isScheduledOnDay(Habit habit, DateTime day, {Habit? progressHabit}) {
    final normalizedDay = _normalizeDate(day);
    final today = _normalizeDate(DateTime.now());
    final isToday = normalizedDay == today;
    switch (habit.scheduleType) {
      case ScheduleType.daily:
        return true;
      case ScheduleType.weekly:
        if (habit.selectedDaysAWeek.isNotEmpty) {
          return habit.selectedDaysAWeek.contains(normalizedDay.weekday);
        }
        if (isToday) {
          final weeklyCount = _effectiveTimesCompletedThisWeek(
            habit,
            normalizedDay,
          );
          return weeklyCount < habit.weeklyTarget;
        }

        return _isCriticalWeekDay(
          progressHabit ?? habit,
          normalizedDay,
          habit.weeklyTarget,
        );
      case ScheduleType.monthly:
        if (habit.selectedDaysAMonth.isNotEmpty) {
          return habit.selectedDaysAMonth.contains(normalizedDay.day);
        }
        if (isToday) {
          final monthlyCount = _effectiveTimesCompletedThisMonth(
            habit,
            normalizedDay,
          );
          return monthlyCount < habit.monthlyTarget;
        }
        return _isCriticalMonthDay(
          progressHabit ?? habit,
          normalizedDay,
          habit.monthlyTarget,
        );
      case ScheduleType.custom:
        _ensureCustomAppearance(habit, normalizedDay);
        final key = normalizedDay.toIso8601String().split('T').first;
        return habit.customAppearance.contains(key);
    }
  }

  // Whether a past day counts toward the streak. Reads the schedule saved in
  // that day's snapshot ([dayHabit]), not the live one, so editing a schedule
  // only changes days from the edit on: switching a daily habit to "every 3
  // days" must not turn its old misses into off-days (and the reverse must not
  // turn old off-days into misses). Pause still comes from the live habit.
  bool _appearedOnPastDay(Habit habit, Habit dayHabit, DateTime day) {
    if (habit.isPaused == true) return false;
    if (_inactiveOnPastDay(habit.id, day)) return false;
    if (dayHabit.scheduleType == ScheduleType.custom) {
      // An empty list means the snapshot never got one, fall back to live.
      // Otherwise read it directly, _isScheduledOnDay would rebuild it in place
      if (dayHabit.customAppearance.isEmpty) {
        return _isScheduledOnDay(habit, day, progressHabit: dayHabit);
      }
      final key = _normalizeDate(day).toIso8601String().split('T').first;
      return dayHabit.customAppearance.contains(key);
    }
    return _isScheduledOnDay(dayHabit, day, progressHabit: dayHabit);
  }

  bool appearsOnDay(Habit habit, DateTime day) {
    return _appearsOnDay(habit, day);
  }

  // How far ahead nextScheduledDate looks. Longest gap a schedule can have is
  // a monthly habit on day 31 (two months), so this always finds a day for
  // anything that is scheduled at all.
  static const int _nextScheduledLookaheadDays = 62;

  /// What a "next scheduled" display shows: today while the habit is still to
  /// do today (scheduled, or kept on by "show again if missed"), otherwise the
  /// next scheduled day. Null when paused or nothing is coming up.
  DateTime? nextAppearance(Habit habit) {
    if (habit.isPaused == true) return null;
    final today = _normalizeDate(DateTime.now());
    if (_appearsOnDay(habit, today) && !habit.completed) return today;
    return nextScheduledDate(habit);
  }

  /// The first day after [from] (default today) the habit is scheduled on, or
  /// null when it is paused or nothing is scheduled within the lookahead.
  /// Callers that want today as well check [appearsOnDay] first.
  DateTime? nextScheduledDate(Habit habit, {DateTime? from}) {
    if (habit.isPaused == true) return null;
    final start = _normalizeDate(from ?? DateTime.now());
    for (var i = 1; i <= _nextScheduledLookaheadDays; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      if (_appearsOnDay(habit, day)) return day;
    }
    return null;
  }

  /// "Other habits" of a past day: habits that existed then but weren't
  /// scheduled and have no progress, so the user can still log one they did
  /// off-schedule (or forgot to tick on a carry-over day). Nothing is written
  /// until the user actually logs progress: the habit is then saved into that
  /// day's snapshot and, having progress, moves into the regular list, where
  /// it counts as a bonus for the streak, never as a miss. Today has none,
  /// off-schedule habits are completed from their details page there.
  List<Habit> otherHabitsForDay(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    if (!normalizedDay.isBefore(_normalizeDate(DateTime.now()))) {
      return const [];
    }
    final snapshot = daysBox.get(_dayKeyOf(normalizedDay));
    final recorded = {for (final h in snapshot?.habits ?? <Habit>[]) h.id: h};

    final result = <Habit>[];
    for (final live in habits) {
      if (live.isDeleted == true || live.isPaused == true) continue;
      if (_normalizeDate(live.createdAt.toLocal()).isAfter(normalizedDay)) {
        continue;
      }
      final candidate =
          _withLiveDetails(recorded[live.id]) ?? live.copyResetCompletion();
      if (candidate.hasAnyProgress()) continue; // already in the regular list
      if (_appearsOnDay(candidate, normalizedDay)) continue; // scheduled
      result.add(candidate);
    }
    _sortHabitsByCategoryAndOrder(result);
    return result;
  }

  // The habit to edit on a past day: the scheduled one from that day's list,
  // or an "Other habits" one (the snapshot copy if the day recorded it, else a
  // fresh copy that updateHabitInDB adds to the snapshot on save).
  Habit? _habitForPastDayEdit(int id, DateTime day) {
    for (final h in getHabitsFromDay(day, hydrateMissing: true)) {
      if (h.id == id) return h;
    }
    for (final h in otherHabitsForDay(day)) {
      if (h.id == id) return h;
    }
    return null;
  }

  // public verson of filtered habits for day
  List<Habit> habitsCountingForDay(DateTime day, List<Habit> source) {
    return _filteredHabitsForDay(day, source);
  }

  // Function to filter habits for a specific day based on their schedule and completion status
  // Display facing: what actually gets shown in the UI
  List<Habit> _filteredHabitsForDay(DateTime day, List<Habit> source) {
    return source
        .where(
          (habit) =>
              (habit.isDeleted != true) &&
              (habit.isPaused != true) &&
              (_countsOnDay(habit, day) || habit.hasAnyProgress()),
        )
        .toList();
  }

  // if habit was scheduled on a day and not paused nor didnt exist
  bool _countsOnDay(Habit habit, DateTime day) =>
      _appearsOnDay(habit, day) && !_inactiveOnPastDay(habit.id, day);

  // whether habit was paused or didnt exit on a past day, so it doesn't count as a miss
  // figured by the pause history and createdAt
  bool inactiveOnPastDay(int habitId, DateTime day) =>
      _inactiveOnPastDay(habitId, day);

  bool _inactiveOnPastDay(int habitId, DateTime day) {
    final normalizedDay = _normalizeDate(day);
    if (!normalizedDay.isBefore(_normalizeDate(DateTime.now()))) return false;
    final live = _liveHabit(habitId);
    if (live == null) return false;
    if (normalizedDay.isBefore(_normalizeDate(live.createdAt.toLocal()))) {
      return true;
    }
    return live.pausedOnDay(normalizedDay);
  }

  // A day snapshot copy doesn't keep the habit's own details (reminders,
  // translated names, streaks, see Habit.habitOnlyKeys), so a copy handed out
  // for showing a past day gets them from the live habit. Filled in on the
  // stored copy in memory only: every day write stores Habit.forDay copies.
  Habit? _withLiveDetails(Habit? copy) {
    if (copy == null) return null;
    final live = _liveHabit(copy.id);
    if (live != null && !identical(live, copy)) copy.adoptHabitOnlyFields(live);
    return copy;
  }

  // The habit record itself, not a day copy. The box too: a sync adds new
  // habits there before they're loaded into [habits].
  Habit? _liveHabit(int id) {
    for (final h in habits) {
      if (h.id == id) return h;
    }
    for (final h in habitBox.values) {
      if (h.id == id) return h;
    }
    return null;
  }

  // Persistence-facing: what actually gets written into a Day snapshot.
  // Deliberately keeps deleted-but-scheduled habits (excluded only from the
  // display variant above) so the day is recorded as a miss and the streak
  // decays normally if the habit is later restored. Paused habits are still
  // excluded — pause remains a full freeze, unlike deletion.
  List<Habit> _scheduledHabitsForDaySnapshot(DateTime day, List<Habit> source) {
    return source
        .where(
          (habit) =>
              (habit.isPaused != true) &&
              (_countsOnDay(habit, day) || habit.hasAnyProgress()),
        )
        .toList();
  }

  int _compareHabitsByOrder(Habit a, Habit b) {
    final categoryCompare = a.categoryId.compareTo(b.categoryId);
    if (categoryCompare != 0) {
      return categoryCompare;
    }

    final aOrder = a.order <= 0 ? 1 << 30 : a.order;
    final bOrder = b.order <= 0 ? 1 << 30 : b.order;
    final orderCompare = aOrder.compareTo(bOrder);
    if (orderCompare != 0) {
      return orderCompare;
    }

    return a.id.compareTo(b.id);
  }

  void _sortHabitsByCategoryAndOrder(List<Habit> source) {
    source.sort(_compareHabitsByOrder);
  }

  int _nextOrderForCategory(int categoryId) {
    int maxOrder = 0;
    for (final habit in habits) {
      if (habit.categoryId != categoryId) {
        continue;
      }
      if (habit.order > maxOrder) {
        maxOrder = habit.order;
      }
    }
    return maxOrder + 1;
  }

  Future<void> _normalizeHabitOrders() async {
    if (habits.isEmpty) {
      return;
    }

    final habitsByCategory = <int, List<Habit>>{};
    for (final habit in habits) {
      habitsByCategory.putIfAbsent(habit.categoryId, () => []).add(habit);
    }

    final now = DateTime.now().toUtc();

    for (final entry in habitsByCategory.entries) {
      final categoryHabits = entry.value;
      categoryHabits.sort((a, b) {
        final aOrder = a.order <= 0 ? 1 << 30 : a.order;
        final bOrder = b.order <= 0 ? 1 << 30 : b.order;
        final orderCompare = aOrder.compareTo(bOrder);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return a.id.compareTo(b.id);
      });

      for (int index = 0; index < categoryHabits.length; index++) {
        final desiredOrder = index + 1;
        final habit = categoryHabits[index];
        if (habit.order == desiredOrder) {
          continue;
        }

        habit.order = desiredOrder;
        habit.timestamps['order'] = now;
        if (habit.isInBox) {
          await habit.save();
        }
      }
    }
  }

  List<Habit> getHabitsForDate(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    final today = _normalizeDate(DateTime.now());
    if (normalizedDay == today) {
      return List<Habit>.from(todaysHabits);
    }
    return getHabitsFromDay(normalizedDay);
  }

  void refreshTodaysHabits({bool notify = true}) {
    final today = _normalizeDate(DateTime.now());
    todaysHabits = _filteredHabitsForDay(today, habits);
    _sortHabitsByCategoryAndOrder(todaysHabits);
    if (notify) {
      notifyListeners();
    }
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
        Day(
          date: today,
          habits: [
            for (final h in _scheduledHabitsForDaySnapshot(today, habits))
              h.forDay(),
          ],
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }
  }

  bool isDayFullyCompleted(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    final dayHabits = getHabitsFromDay(normalizedDay, hydrateMissing: true);

    int requiredHabits = 0;
    int satisfiedHabits = 0;

    for (final habit in dayHabits) {
      if (habit.optional) {
        continue;
      }

      requiredHabits++;
      if (habit.completed || habit.skipped) {
        satisfiedHabits++;
      }
    }

    return requiredHabits > 0 && satisfiedHabits >= requiredHabits;
  }

  void playCompletionSound(
    BuildContext context,
    DateTime day, {
    required bool isOptionalHabit,
  }) {
    if (!context.read<PreferencesProvider>().playCompletionSound) return;
    unawaited(
      CompletionSoundPlayer.instance.play(
        allHabitsCompleted: !isOptionalHabit && isDayFullyCompleted(day),
      ),
    );
  }

  void _refreshPerfectStreakForDayIfNeeded(DateTime day) {
    if (statsProvider == null) {
      return;
    }

    // Always recompute after a completion-state transition. This keeps the
    // streak correct when a day becomes perfect and when it loses perfection.
    isDayFullyCompleted(day);

    statsProvider!.perfectDaysStreak = statsProvider!.refreshPerfectStreak();
  }

  /// Completing/skipping habits that complete *yesterday* can immediately
  /// increase the perfect-days streak (today is excluded from the streak), so
  /// back-filling yesterday should celebrate in the same session. The dialog
  /// always anchors on yesterday, so completing today (never bumps the streak)
  /// or any day older than yesterday does not trigger it.
  void _maybeCelebratePastDayStreak(
    BuildContext context,
    DateTime daySimple,
    DateTime todaySimple,
  ) {
    final yesterday = DateTime(
      todaySimple.year,
      todaySimple.month,
      todaySimple.day - 1,
    );
    if (daySimple != yesterday || !context.mounted) {
      return;
    }
    unawaited(runStreakMoment(context));
  }

  Map<DateTime, double> getThisWeekProgress({DateTime? anchorDate}) {
    final baseDate = _normalizeDate(anchorDate ?? DateTime.now());
    final startOfWeek = addCalendarDays(baseDate, -(baseDate.weekday - 1));

    List<Day> thisWeekDays = [];

    for (int i = 0; i < 7; i++) {
      thisWeekDays.add(
        Day(
          date: addCalendarDays(startOfWeek, i),
          habits: getHabitsFromDay(addCalendarDays(startOfWeek, i)),
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }

    // Calculating progress for each day 0 - 1

    final Map<DateTime, double> daysProgress = {};

    for (final day in thisWeekDays) {
      final totalHabits = day.habits.isEmpty ? 1 : day.habits.length;
      final completedWeight = day.habits.fold<double>(0.0, (sum, habit) {
        if (habit.completed) {
          return sum + 1.0;
        }

        if (habit.tracksAmount) {
          if (habit.amount <= 0) {
            return sum;
          }
          return sum + (habit.amountCompleted / habit.amount).clamp(0.0, 1.0);
        }

        if (habit.tracksDuration) {
          if (habit.duration <= 0) {
            return sum;
          }
          return sum +
              (habit.durationCompleted / habit.duration).clamp(0.0, 1.0);
        }

        return sum;
      });

      daysProgress[day.date] = (completedWeight / totalHabits).clamp(0.0, 1.0);
    }

    return daysProgress;
  }

  // DAY PROGRESS CACHE

  final Map<DateTime, double> _dayProgressCache = {}; // 0 to 1
  int _dayProgressCacheVersion = -1;

  void _ensureDayProgressCacheVersion() {
    if (_dayProgressCacheVersion != dataVersion) {
      _dayProgressCache.clear();
      _dayProgressCacheVersion = dataVersion;
    }
  }

  // Cached progress for a day or null if it hasn't been computed yet.
  double? cachedDayProgress(DateTime day) {
    _ensureDayProgressCacheVersion();
    return _dayProgressCache[_normalizeDate(day)];
  }

  // Progress for day, computing and caching its whole week
  double dayProgress(DateTime day) {
    _ensureDayProgressCacheVersion();
    final normalized = _normalizeDate(day);
    final cached = _dayProgressCache[normalized];
    if (cached != null) return cached;
    _cacheWeekProgress(normalized);
    return _dayProgressCache[normalized] ?? 0.0;
  }

  // Ensures every day has a cached progress value
  void primeDayProgress(Iterable<DateTime> days) {
    _ensureDayProgressCacheVersion();
    for (final day in days) {
      final normalized = _normalizeDate(day);
      if (!_dayProgressCache.containsKey(normalized)) {
        _cacheWeekProgress(normalized);
      }
    }
  }

  // Recalculate after data changes
  double refreshDayProgress(DateTime day) {
    _ensureDayProgressCacheVersion();
    final normalized = _normalizeDate(day);
    _cacheWeekProgress(normalized);
    return _dayProgressCache[normalized] ?? 0.0;
  }

  void _cacheWeekProgress(DateTime anchorDay) {
    final today = _normalizeDate(DateTime.now());
    final weekProgress = getThisWeekProgress(anchorDate: anchorDay);
    weekProgress.forEach((date, value) {
      _dayProgressCache[date] =
          date.isAfter(today) ? 0.0 : value.clamp(0.0, 1.0);
    });
  }

  Future<void> updateHabitInDB(Habit habit, {DateTime? day}) async {
    // debugPrint("Updating habit in DB: ${habit.name}");
    habitStatsProvider?.invalidateHabit(habit.id);
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

    // Only the live habit's schedule moves, a past day's snapshot keeps the
    // schedule it was recorded with
    final scheduleMoved = _syncCustomRestartForDay(
      realHabit,
      usedDay,
      completedOnDay: habit.completed,
    );
    final isPastDay = _normalizeDate(usedDay) != _normalizeDate(DateTime.now());
    if (scheduleMoved && isPastDay) {
      await _syncTodaySnapshotSchedule(realHabit);
      // the future schedule moved, so do its reminders
      unawaited(syncSingleHabitNotifications(realHabit));
    }

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
      // a copy, never the passed instance: that's often the live habit, and
      // the snapshot would then change along with it (and hold its pause
      // history, which stays on the habit)
      if (index != -1) {
        dayEntry.habits[index] = habit.forDay();
      } else {
        debugPrint("Habit not found in day entry");
        dayEntry.habits.add(habit.forDay());
      }
      await daysBox.put(
        dayKey,
        Day(
          date: dayEntry.date,
          // the rest of the day's copies may hold the live habit's details
          // filled in for showing them (see _withLiveDetails)
          habits: [for (final h in dayEntry.habits) h.forDay()],
          timestamp: DateTime.now().toUtc(),
        ),
      );
    } else {
      debugPrint("Day entry is null");
      saveHabitDay(usedDay);
    }
  }

  // Function used to get list of habits from a specific day from database
  List<Habit> getHabitsFromDay(DateTime day, {bool hydrateMissing = false}) {
    final normalizedDay = _normalizeDate(day);
    final today = _normalizeDate(DateTime.now());
    if (normalizedDay == today) {
      return List<Habit>.from(todaysHabits);
    }

    final dayKey = normalizedDay.toIso8601String().split('T').first;
    Day? dayEntry = daysBox.get(dayKey);
    List<Habit> dayHabits = dayEntry?.habits ?? [];

    // Optionally hydrate missing days (only when explicitly requested)
    if (hydrateMissing &&
        dayHabits.isEmpty &&
        normalizedDay.isBefore(today) &&
        (_dateJoined == null || normalizedDay.isAfter(_dateJoined!)) &&
        habits.isNotEmpty) {
      saveHabitDay(normalizedDay, resetCompletion: true, isAutoCreated: true);
      dayEntry = daysBox.get(dayKey);
      dayHabits = dayEntry?.habits ?? [];
    }

    final filteredHabits = _filteredHabitsForDay(normalizedDay, dayHabits);
    filteredHabits.forEach(_withLiveDetails);
    _sortHabitsByCategoryAndOrder(filteredHabits);
    return filteredHabits;
  }

  void addHabit(Habit habit) {
    if (statsProvider != null) {
      statsProvider!.addShouldRefresh(StatsType.highestAmountOfHabitsLastWeek);
    }

    if (habit.order <= 0) {
      habit.order = _nextOrderForCategory(habit.categoryId);
      habit.timestamps['order'] = DateTime.now().toUtc();
    }

    habits.add(habit);
    habitStatsProvider?.invalidateHabit(habit.id);
    _sortHabitsByCategoryAndOrder(habits);
    habitBox.add(habit);
    updateHabitInDB(habit);
    refreshTodaysHabits(notify: false);

    // Scheduels notifications for added habit
    syncSingleHabitNotifications(habit);

    notifyListeners();
  }

  Future<void> reorderHabitsInCategory({
    required int categoryId,
    required int oldIndex,
    required int newIndex,
    required bool todaysOnly,
    bool separateOptional = false,
  }) async {
    if (oldIndex < 0 || newIndex < 0 || oldIndex == newIndex) {
      return;
    }

    // the indices come from the visible cards, so deleted habits (hidden there)
    // stay out of the shuffle and keep their slots at the end. With separated
    // optional habits only the required habits of the category move
    bool inScope(Habit h) =>
        h.isDeleted != true && !(separateOptional && h.optional);

    final allCategoryHabits =
        habits.where((h) => h.categoryId == categoryId).toList();
    allCategoryHabits.sort((a, b) {
      final aOrder = a.order <= 0 ? 1 << 30 : a.order;
      final bOrder = b.order <= 0 ? 1 << 30 : b.order;
      final orderCompare = aOrder.compareTo(bOrder);
      if (orderCompare != 0) {
        return orderCompare;
      }
      return a.id.compareTo(b.id);
    });

    final categoryHabits = allCategoryHabits.where(inScope).toList();
    final outOfScopeHabits =
        allCategoryHabits.where((h) => !inScope(h)).toList();
    if (categoryHabits.length < 2) {
      return;
    }

    late final List<Habit> reorderedCategory;

    if (!todaysOnly) {
      if (oldIndex >= categoryHabits.length ||
          newIndex >= categoryHabits.length) {
        return;
      }

      reorderedCategory = List<Habit>.from(categoryHabits);
      final moved = reorderedCategory.removeAt(oldIndex);
      reorderedCategory.insert(newIndex, moved);
    } else {
      final scheduledCategoryHabits =
          todaysHabits
              .where((h) => h.categoryId == categoryId && inScope(h))
              .toList();
      if (oldIndex >= scheduledCategoryHabits.length ||
          newIndex >= scheduledCategoryHabits.length ||
          scheduledCategoryHabits.length < 2) {
        return;
      }

      final reorderedScheduled = List<Habit>.from(scheduledCategoryHabits);
      final movedScheduled = reorderedScheduled.removeAt(oldIndex);
      reorderedScheduled.insert(newIndex, movedScheduled);

      final scheduledIdSet = scheduledCategoryHabits.map((h) => h.id).toSet();
      int scheduledCursor = 0;
      reorderedCategory = [];

      for (final habit in categoryHabits) {
        if (!scheduledIdSet.contains(habit.id)) {
          reorderedCategory.add(habit);
          continue;
        }

        reorderedCategory.add(reorderedScheduled[scheduledCursor]);
        scheduledCursor += 1;
      }
    }

    reorderedCategory.addAll(outOfScopeHabits);

    final now = DateTime.now().toUtc();
    final changedHabits = <Habit>[];

    for (int index = 0; index < reorderedCategory.length; index++) {
      final habit = reorderedCategory[index];
      final desiredOrder = index + 1;
      if (habit.order == desiredOrder) {
        continue;
      }

      habit.order = desiredOrder;
      habit.timestamps['order'] = now;
      changedHabits.add(habit);
    }

    _sortHabitsByCategoryAndOrder(habits);
    refreshTodaysHabits(notify: false);
    notifyListeners();

    for (final habit in changedHabits) {
      if (habit.isInBox) {
        await habit.save();
      }
    }

    backupProvider?.scheduleAutoSync();
  }

  // reorders the optional habits as one list, whatever their category
  Future<void> reorderOptionalHabits({
    required List<Category> categories,
    required List<Habit> visible,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 ||
        newIndex < 0 ||
        oldIndex == newIndex ||
        oldIndex >= visible.length ||
        newIndex >= visible.length) {
      return;
    }

    final reorderedVisible = List<Habit>.from(visible);
    reorderedVisible.insert(newIndex, reorderedVisible.removeAt(oldIndex));

    final all = sortOptionalHabits(
      habits.where((h) => h.optional && h.isDeleted != true),
      categories,
    );
    final visibleIds = visible.map((h) => h.id).toSet();
    int visibleCursor = 0;
    final reordered = [
      for (final habit in all)
        visibleIds.contains(habit.id)
            ? reorderedVisible[visibleCursor++]
            : habit,
    ];

    final now = DateTime.now().toUtc();
    final changedHabits = <Habit>[];
    for (int index = 0; index < reordered.length; index++) {
      final habit = reordered[index];
      final desiredOrder = index + 1;
      if (habit.optionalOrder == desiredOrder) {
        continue;
      }

      habit.optionalOrder = desiredOrder;
      habit.timestamps['optionalOrder'] = now;
      changedHabits.add(habit);
    }

    refreshTodaysHabits(notify: false);
    notifyListeners();

    for (final habit in changedHabits) {
      if (habit.isInBox) {
        await habit.save();
      }
    }

    backupProvider?.scheduleAutoSync();
  }

  void removeHabit(Habit habit, BuildContext context) async {
    if (statsProvider != null) {
      statsProvider!.addShouldRefresh(StatsType.highestAmountOfHabitsLastWeek);
    }

    habitStatsProvider?.removeHabit(habit.id);
    onHabitDeactivated?.call(habit.id);
    await habit.deleteHabit();
    // Cancels deleted habit notifications
    await NotificationService.cancelHabitNotifications(habit);
    if (context.mounted) checkReorderCategories(context, habit);

    updateHabitInDB(habit);
    refreshTodaysHabits(notify: false);
    notifyListeners();
  }

  Future<void> pauseHabit(Habit habit) async {
    onHabitDeactivated?.call(habit.id);
    await habit.pauseHabit();
    await NotificationService.cancelHabitNotifications(habit);
    updateHabitInDB(habit);
    refreshTodaysHabits(notify: false);
    notifyListeners();
  }

  Future<void> unpauseHabit(Habit habit) async {
    await habit.unpauseHabit();
    syncSingleHabitNotifications(habit);
    updateHabitInDB(habit);
    refreshTodaysHabits(notify: false);
    notifyListeners();
  }

  Future<void> restoreHabit(Habit habit) async {
    await habit.restore();
    notifyListeners();
    syncSingleHabitNotifications(habit);
    updateHabitInDB(habit);
    refreshTodaysHabits(notify: false);

    await recalculateHabitStreaks(habit.id);
    notifyListeners();
  }

  void completeHabit(
    int id,
    BuildContext context,
    StateProvider stateProvider, {
    bool playSound = true,
  }) async {
    late Habit habit;

    final today = DateTime.now();
    final _selectedDate = selectedDate ?? today;
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      // includes "Other habits", which aren't in the day's regular list
      final dayHabit = _habitForPastDayEdit(id, daySimple);
      if (dayHabit == null) return;
      habit = dayHabit;
      if (!stateProvider.shouldUpdateStreaks) {
        stateProvider.shouldUpdateStreaks = true;
      }
    }

    debugPrint("Completing habit: $id, day: $daySimple");
    habitStatsProvider?.invalidateHabit(id);
    final wasCompleted = habit.completed;
    // un-skipping resets progress to 0, which isn't an edit worth freezing
    final pausesHealthSync =
        !habit.skipped &&
        habit.healthMetric != null &&
        !habit.healthManualOverride;
    if (!habit.skipped) _markHealthManualOverride(habit);
    await habit.completeHabit();
    debugPrint("Habit completed: ${habit.completed}");
    if (playSound && !wasCompleted && habit.completed && context.mounted) {
      playCompletionSound(context, daySimple, isOptionalHabit: habit.optional);
    }
    final currentHabit = habits.firstWhere((h) => h.id == id);
    _updatePeriodCountersOnCompletionChange(
      currentHabit: currentHabit,
      wasCompleted: wasCompleted,
      isCompleted: habit.completed,
      daySimple: daySimple,
      todaySimple: todaySimple,
    );
    if (context.mounted && daySimple == todaySimple) {
      // Reordering categories if today
      checkReorderCategories(context, habit);
    }

    await updateHabitInDB(habit, day: daySimple);
    await _syncNotificationsOnCompletionChange(
      habit: currentHabit,
      wasCompleted: wasCompleted,
      isNowCompleted: habit.completed,
      daySimple: daySimple,
      todaySimple: todaySimple,
    );
    _refreshPerfectStreakForDayIfNeeded(daySimple);

    if (daySimple != todaySimple) {
      await assignStreaks(id);
    }

    if (!wasCompleted && habit.completed) {
      unawaited(_countCompletion());
    }

    refreshTodaysHabits(notify: false);
    notifyListeners();

    if (pausesHealthSync && context.mounted) {
      // the dialog informing the user that health sync is paused
      unawaited(HealthOverrideNotice.showIfNeeded(context));
    }

    if (!wasCompleted && habit.completed) {
      _maybeCelebratePastDayStreak(context, daySimple, todaySimple);
    }
  }

  // completes a habit noted by the notification complete button
  void applyDeferredCompletion(
    int id,
    DateTime day,
    BuildContext context,
    StateProvider stateProvider,
  ) {
    final today = DateTime.now();
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(day.year, day.month, day.day);

    Habit? habit;
    final source =
        daySimple == todaySimple
            ? habits
            : getHabitsFromDay(daySimple, hydrateMissing: true);
    for (final h in source) {
      if (h.id == id) {
        habit = h;
        break;
      }
    }

    debugPrint(
      '[NOTIF_DRAIN] applyDeferredCompletion id=$id day=$daySimple '
      'found=${habit != null} alreadyCompleted=${habit?.completed}',
    );
    if (habit == null || habit.completed) return; // missing or already done
    // Completed from the notification's button, not in-app — stay silent.
    completeHabit(id, context, stateProvider, playSound: false);
  }

  void skipHabit(
    int id,
    BuildContext context,
    StateProvider stateProvider, {
    required DateTime day,
  }) async {
    debugPrint("Skipping habit: $id");
    habitStatsProvider?.invalidateHabit(id);
    late Habit habit;
    Habit? habitDayBefore;

    final today = DateTime.now();
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(day.year, day.month, day.day);
    final dayBefore = addCalendarDays(daySimple, -1);

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      final List<Habit> dayHabits = getHabitsFromDay(day, hydrateMissing: true);
      habit = dayHabits.firstWhere((h) => h.id == id);
      if (!stateProvider.shouldUpdateStreaks) {
        stateProvider.shouldUpdateStreaks = true;
      }
    }

    final List<Habit> dayBeforeHabits = getHabitsFromDay(dayBefore);
    if (dayBeforeHabits.isNotEmpty) {
      habitDayBefore = dayBeforeHabits.firstWhere((h) => h.id == id);
    }

    if (habitDayBefore != null && habitDayBefore.skipped) {
      debugPrint("Skipping habit not allowed, habit day before skipped");
      return;
    }

    await habit.skipHabit();
    if (context.mounted && daySimple == todaySimple) {
      checkReorderCategories(context, habit);
    }
    await updateHabitInDB(habit, day: day);
    if (daySimple != todaySimple) {
      await assignStreaks(id);
    }
    refreshTodaysHabits(notify: false);
    notifyListeners();

    if (habit.skipped) {
      _maybeCelebratePastDayStreak(context, daySimple, todaySimple);
    }
  }

  void updateHabit(Habit habit) {
    habitStatsProvider?.invalidateHabit(habit.id);
    final persistedHabit = habits.where((h) => h.id == habit.id).first;
    final previousSlots =
        persistedHabit.notificationTimes.map((slot) => slot.copy()).toList();
    persistedHabit.updateHabit(habit);
    // The persisted habit, not the edited copy: only it carries the timestamps
    // of this edit. A copy keeps the pre-edit ones, so today's snapshot would
    // lose the edit (optional, schedule, ...) to the other device on a sync.
    updateHabitInDB(persistedHabit);
    refreshTodaysHabits(notify: false);
    // The reschedule below only cancels the habit's current slots, so slots the
    // edit replaced or removed would keep ringing at their old time.
    unawaited(
      NotificationService.cancelRemovedSlotNotifications(
        persistedHabit.id,
        HabitNotificationTime.removedSlots(
          previousSlots,
          persistedHabit.notificationTimes,
        ),
      ),
    );
    syncSingleHabitNotifications(persistedHabit);

    notifyListeners();
  }

  Future<void> resetCompletion() async {
    habitStatsProvider?.clearAll();
    for (final habit in habits) {
      await habit.resetCompletion();
      await updateHabitInDB(habit);
    }
    refreshTodaysHabits(notify: false);
    _syncAllHabitNotifications(force: true);
    notifyListeners();
  }

  /// Restores today's day-state from today's stored snapshot, if one exists.
  ///
  /// Used when the device clock moves backwards (e.g. the user set the date a
  /// few days ahead, then back): the live habits hold the "future" day's state,
  /// while today's real progress was snapshotted when the clock moved ahead.
  /// Falls back to [resetCompletion] when there is no snapshot for today.
  Future<void> restoreTodayFromSnapshot() async {
    final today = _normalizeDate(DateTime.now());
    final todayKey = today.toIso8601String().split('T').first;
    final snapshot = daysBox.get(todayKey);
    if (snapshot == null) {
      await resetCompletion();
      return;
    }

    habitStatsProvider?.clearAll();
    final snapshotById = {for (final h in snapshot.habits) h.id: h};
    for (final habit in habits) {
      final dayHabit = snapshotById[habit.id];
      if (dayHabit != null) {
        habit.adoptDayState(dayHabit);
      } else {
        await habit.resetCompletion();
      }
      await updateHabitInDB(habit);
    }
    refreshTodaysHabits(notify: false);
    _syncAllHabitNotifications(force: true);
    notifyListeners();
  }

  Future<void> resetScheduleCountersIfNeeded({
    required bool resetWeekly,
    required bool resetMonthly,
  }) async {
    if (!resetWeekly && !resetMonthly) {
      return;
    }

    habitStatsProvider?.clearAll();

    for (final habit in habits) {
      await habit.resetScheduleCounters(
        resetWeekly: resetWeekly,
        resetMonthly: resetMonthly,
      );
      await updateHabitInDB(habit);
    }

    refreshTodaysHabits(notify: false);
    _syncAllHabitNotifications(force: true);
    notifyListeners();
  }

  // weekly/monthly habits track how many times they were completed in the period
  // needs to be called on every completion flip to keep the counters accurate
  void _updatePeriodCountersOnCompletionChange({
    required Habit currentHabit,
    required bool wasCompleted,
    required bool isCompleted,
    required DateTime daySimple,
    required DateTime todaySimple,
  }) {
    // check if in current period (week/month)
    // this is because user can complete a habit from a past day
    final shouldAffectCurrentPeriod =
        (currentHabit.scheduleType == ScheduleType.weekly &&
            _isSameWeek(daySimple, todaySimple)) ||
        (currentHabit.scheduleType == ScheduleType.monthly &&
            _isSameMonth(daySimple, todaySimple));

    if (!shouldAffectCurrentPeriod) return;

    // If it affects current period we update habit schedule counters
    final weeklyBaseCount =
        currentHabit.scheduleType == ScheduleType.weekly
            ? _effectiveTimesCompletedThisWeek(currentHabit, daySimple)
            : null;
    final monthlyBaseCount =
        currentHabit.scheduleType == ScheduleType.monthly
            ? _effectiveTimesCompletedThisMonth(currentHabit, daySimple)
            : null;

    currentHabit.updateScheduleCountersOnCompletionToggle(
      wasCompleted: wasCompleted,
      isCompleted: isCompleted,
      weeklyBaseCount: weeklyBaseCount,
      monthlyBaseCount: monthlyBaseCount,
    );
  }

  /// Same as [_updatePeriodCountersOnCompletionChange] for callers that only
  // have an id and whose day habit may not be the real habit (past days).
  void _updatePeriodCountersForId(
    int id, {
    required bool wasCompleted,
    required bool isCompleted,
    required DateTime daySimple,
    required DateTime todaySimple,
  }) {
    final real = habits.where((h) => h.id == id);
    if (real.isEmpty) return;
    _updatePeriodCountersOnCompletionChange(
      currentHabit: real.first,
      wasCompleted: wasCompleted,
      isCompleted: isCompleted,
      daySimple: daySimple,
      todaySimple: todaySimple,
    );
  }

  void updateHabitAmountCompleted(
    int id,
    int amountCompleted,
    BuildContext context,
  ) async {
    habitStatsProvider?.invalidateHabit(id);
    late Habit habit;

    final today = DateTime.now();
    final _selectedDate = selectedDate ?? today;
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      // includes "Other habits", which aren't in the day's regular list
      final dayHabit = _habitForPastDayEdit(id, daySimple);
      if (dayHabit == null) return;
      habit = dayHabit;
    }

    final wasCompleted = habit.completed;
    debugPrint("Habit was completed: $wasCompleted");
    _markHealthManualOverride(habit);
    // bedtime/wake time are clock times where earlier is better, so they
    // complete differently from a plain amount
    if (habit.tracksTimeOfDay) {
      habit.updateHabitTimeOfDayCompleted(amountCompleted);
    } else {
      habit.updateHabitAmountCompleted(amountCompleted);
    }
    final isNowCompleted = habit.completed;
    if (!wasCompleted && isNowCompleted) {
      playCompletionSound(context, daySimple, isOptionalHabit: habit.optional);
    }
    debugPrint("Habit is now completed: $isNowCompleted");
    if (wasCompleted != isNowCompleted) {
      _updatePeriodCountersOnCompletionChange(
        currentHabit: habits.firstWhere((h) => h.id == id),
        wasCompleted: wasCompleted,
        isCompleted: isNowCompleted,
        daySimple: daySimple,
        todaySimple: todaySimple,
      );
      if (daySimple != todaySimple) {
        context.read<StateProvider>().shouldUpdateStreaks = true;
      }
    }
    if (context.mounted) checkReorderCategories(context, habit);

    await updateHabitInDB(habit, day: daySimple);
    await _syncNotificationsOnCompletionChange(
      habit: habit,
      wasCompleted: wasCompleted,
      isNowCompleted: isNowCompleted,
      daySimple: daySimple,
      todaySimple: todaySimple,
    );
    _refreshPerfectStreakForDayIfNeeded(daySimple);
    if (wasCompleted != isNowCompleted && daySimple != todaySimple) {
      await assignStreaks(id);
    }
    refreshTodaysHabits(notify: false);
    notifyListeners();

    if (!wasCompleted && isNowCompleted) {
      _maybeCelebratePastDayStreak(context, daySimple, todaySimple);
    }
  }

  int? timerTargetDuration(int id, {required DateTime day}) {
    final normalizedDay = _normalizeDate(day);
    final List<Habit> source;
    if (normalizedDay == _normalizeDate(DateTime.now())) {
      source = todaysHabits;
    } else {
      final dayKey = normalizedDay.toIso8601String().split('T').first;
      source = daysBox.get(dayKey)?.habits ?? const <Habit>[];
    }

    for (final h in source) {
      if (h.id == id) return h.tracksDuration ? h.duration : null;
    }
    return null;
  }

  /// Looks up a single habit by id for [day]. Used by the timer to resolve
  /// the habit's name when scheduling its completion notification.
  Habit? habitForDay(int id, {required DateTime day}) {
    final normalizedDay = _normalizeDate(day);
    final List<Habit> source;
    if (normalizedDay == _normalizeDate(DateTime.now())) {
      source = todaysHabits;
    } else {
      final dayKey = normalizedDay.toIso8601String().split('T').first;
      source = daysBox.get(dayKey)?.habits ?? const <Habit>[];
    }

    for (final h in source) {
      if (h.id == id) return _withLiveDetails(h);
    }
    return null;
  }

  // used by the timer provider to commit timer progress to the habit
  // after pausing or stopping the timer
  Future<void> commitTimerDuration(
    int id,
    int durationCompleted, {
    required DateTime day,
  }) async {
    habitStatsProvider?.invalidateHabit(id);

    final now = DateTime.now();
    final todaySimple = DateTime(now.year, now.month, now.day);
    final daySimple = DateTime(day.year, day.month, day.day);

    late Habit habit;
    if (daySimple == todaySimple) {
      final match = habits.where((h) => h.id == id);
      if (match.isEmpty) return;
      habit = match.first;
    } else {
      final dayHabits = getHabitsFromDay(daySimple, hydrateMissing: true);
      final match = dayHabits.where((h) => h.id == id);
      if (match.isEmpty) return;
      habit = match.first;
    }

    final wasCompleted = habit.completed;
    habit.updateHabitDurationCompleted(durationCompleted);
    final isNowCompleted = habit.completed;
    if (wasCompleted != isNowCompleted) {
      _updatePeriodCountersForId(
        id,
        wasCompleted: wasCompleted,
        isCompleted: isNowCompleted,
        daySimple: daySimple,
        todaySimple: todaySimple,
      );
    }

    await updateHabitInDB(habit, day: daySimple);

    // notification rescheduling, perfect-streak recompute, and the today's-list
    // resort are only relevant when this tick actually crossed the completion
    // threshold — a mid-progress pause/stop changes nothing they depend on.
    if (wasCompleted != isNowCompleted) {
      await _syncNotificationsOnCompletionChange(
        habit: habit,
        wasCompleted: wasCompleted,
        isNowCompleted: isNowCompleted,
        daySimple: daySimple,
        todaySimple: todaySimple,
      );
      _refreshPerfectStreakForDayIfNeeded(daySimple);
      if (daySimple != todaySimple) await assignStreaks(id);
      refreshTodaysHabits(notify: false);
    }
    notifyListeners();
  }

  // manually added progress to a health habit
  void _markHealthManualOverride(Habit habit) {
    if (habit.healthMetric != null) habit.healthManualOverride = true;
  }

  // user changed back to health sync after manually overriding a habit's progress
  Future<void> clearHealthManualOverride(
    int id, {
    required DateTime day,
  }) async {
    habitStatsProvider?.invalidateHabit(id);

    final now = DateTime.now();
    final todaySimple = DateTime(now.year, now.month, now.day);
    final daySimple = DateTime(day.year, day.month, day.day);

    final source =
        daySimple == todaySimple
            ? habits
            : getHabitsFromDay(daySimple, hydrateMissing: true);
    final match = source.where((h) => h.id == id);
    if (match.isEmpty) return;
    final habit = match.first;
    if (!habit.healthManualOverride) return;

    habit.healthManualOverride = false;
    // the flag has no timestamp of its own and follows the completion tuple
    // in a merge, so stamp the tuple: otherwise the cleared flag loses to the
    // other device's (identical) tuple and Health never takes the day back
    habit.timestamps['completed'] = DateTime.now().toUtc();
    await updateHabitInDB(habit, day: daySimple);
    notifyListeners();
  }

  // the habit's snapshot for [day] as a Health sync would write to it, or null
  // when the habit isn't on that day (not created yet, paused, not scheduled).
  // Past days are created on demand like everywhere else a past day is opened.
  Habit? _habitForHealthSync(int id, DateTime daySimple) {
    final today = _normalizeDate(DateTime.now());
    final source =
        daySimple == today
            ? habits
            : getHabitsFromDay(daySimple, hydrateMissing: true);
    final match = source.where((h) => h.id == id);
    return match.isEmpty ? null : match.first;
  }

  /// Whether a Health sync could write to habit [id] on [day]. Lets a catch-up
  /// skip the Health read for days the habit doesn't appear on.
  bool canSyncHealthDay(int id, DateTime day) =>
      _habitForHealthSync(id, _normalizeDate(day)) != null;

  // applies a value read from Health to the habit it's linked to.
  // [refreshStreaks] is off while catching up on several past days, so the
  // caller can run assignStreaks once at the end instead of once per day
  Future<HealthApplyOutcome> syncHabitFromHealth(
    int id,
    HealthMetricType metric,
    int rawValue, {
    required DateTime day,
    List<HealthSessionDetail> sessions = const [],
    bool refreshStreaks = true,
  }) async {
    // no stats invalidation here: every path that writes goes through
    // updateHabitInDB, which does it, and a sync that changes nothing must
    // leave caches, the DB, notifications and backup alone
    final now = DateTime.now();
    final todaySimple = DateTime(now.year, now.month, now.day);
    final daySimple = DateTime(day.year, day.month, day.day);

    final habit = _habitForHealthSync(id, daySimple);
    if (habit == null) {
      return const HealthApplyOutcome(HealthApplyStatus.skipped);
    }

    // if habit got unlinked by user, dont apply wrongly,
    // instead wait for next sync to reapply if linked differently
    if (habit.healthMetric != metric) {
      return const HealthApplyOutcome(HealthApplyStatus.skipped);
    }

    // user edited this day by hand: leave the progress alone but keep the
    // session list current, it's informational only
    if (habit.healthManualOverride) {
      if (sameHealthSessions(habit.healthSessions, sessions)) {
        return const HealthApplyOutcome(HealthApplyStatus.applied);
      }
      habit.healthSessions = sessions.map((s) => s.copy()).toList();
      await updateHabitInDB(habit, day: daySimple);
      notifyListeners();
      return const HealthApplyOutcome(HealthApplyStatus.applied);
    }

    final wasCompleted = habit.completed;

    // assign tracking type based on selected or default one
    final effectiveTrackingType =
        metric.supportsTrackingChoice
            ? (habit.trackingType ?? metric.trackingType)
            : metric.trackingType;

    // an empty or corrupt read must not wipe what the day already has
    final existingProgress =
        effectiveTrackingType == HabitTrackingType.duration
            ? habit.durationCompleted
            : habit.amountCompleted;
    if (shouldDiscardHealthValue(
      metric,
      rawValue,
      existingProgress,
      trackingType: effectiveTrackingType,
    )) {
      return const HealthApplyOutcome(HealthApplyStatus.discarded);
    }

    // the update methods stamp the progress/completed timestamps even when the
    // value is the same, and backup merge goes by those. Remember them, so a
    // read that changes nothing can put them back instead of looking like an edit
    const stampedKeys = ['amountCompleted', 'durationCompleted', 'completed'];
    final savedStamps = <String, DateTime?>{
      for (final key in stampedKeys) key: habit.timestamps[key],
    };
    final previousSessions = habit.healthSessions;

    switch (effectiveTrackingType) {
      case HabitTrackingType.amount:
        habit.updateHabitAmountCompleted(rawValue);
        break;
      case HabitTrackingType.duration:
        habit.updateHabitDurationCompleted(rawValue);
        break;
      case HabitTrackingType.timeOfDay:
        habit.updateHabitTimeOfDayCompleted(rawValue);
        break;
    }
    habit.healthSessions = sessions.map((s) => s.copy()).toList();

    // a workout/mindfulness habit with no target set (0) would
    // always read as complete even with no sessions logged
    // override: complete only if anything was logged
    if (metric.supportsTrackingChoice) {
      final target =
          effectiveTrackingType == HabitTrackingType.amount
              ? habit.amount
              : habit.duration;
      if (target == 0) {
        final zeroTargetCompleted = sessions.isNotEmpty;
        if (habit.completed != zeroTargetCompleted) {
          habit.completed = zeroTargetCompleted;
          habit.timestamps['completed'] = DateTime.now().toUtc();
        }
      }
    }

    final isNowCompleted = habit.completed;

    // same progress, same completion, same sessions: nothing to save, notify
    // or back up (this is the common case, today is re-read on every app open)
    final newProgress =
        effectiveTrackingType == HabitTrackingType.duration
            ? habit.durationCompleted
            : habit.amountCompleted;
    if (newProgress == existingProgress &&
        wasCompleted == isNowCompleted &&
        sameHealthSessions(previousSessions, sessions)) {
      savedStamps.forEach((key, stamp) {
        if (stamp == null) {
          habit.timestamps.remove(key);
        } else {
          habit.timestamps[key] = stamp;
        }
      });
      return const HealthApplyOutcome(HealthApplyStatus.applied);
    }

    if (wasCompleted != isNowCompleted) {
      _updatePeriodCountersForId(
        id,
        wasCompleted: wasCompleted,
        isCompleted: isNowCompleted,
        daySimple: daySimple,
        todaySimple: todaySimple,
      );
    }

    await updateHabitInDB(habit, day: daySimple);

    if (wasCompleted != isNowCompleted) {
      await _syncNotificationsOnCompletionChange(
        habit: habit,
        wasCompleted: wasCompleted,
        isNowCompleted: isNowCompleted,
        daySimple: daySimple,
        todaySimple: todaySimple,
      );
      _refreshPerfectStreakForDayIfNeeded(daySimple);
      if (daySimple != todaySimple && refreshStreaks) await assignStreaks(id);
      refreshTodaysHabits(notify: false);
    }
    notifyListeners();
    return HealthApplyOutcome(
      HealthApplyStatus.applied,
      completionChanged: wasCompleted != isNowCompleted,
    );
  }

  void updateHabitDurationCompleted(
    int id,
    int durationCompleted,
    BuildContext context,
  ) async {
    habitStatsProvider?.invalidateHabit(id);
    late Habit habit;

    final today = DateTime.now();
    final _selectedDate = selectedDate ?? today;
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      // includes "Other habits", which aren't in the day's regular list
      final dayHabit = _habitForPastDayEdit(id, daySimple);
      if (dayHabit == null) return;
      habit = dayHabit;
    }

    final wasCompleted = habit.completed;
    _markHealthManualOverride(habit);
    habit.updateHabitDurationCompleted(durationCompleted);
    final isNowCompleted = habit.completed;
    if (!wasCompleted && isNowCompleted) {
      playCompletionSound(context, daySimple, isOptionalHabit: habit.optional);
    }
    if (wasCompleted != isNowCompleted) {
      _updatePeriodCountersOnCompletionChange(
        currentHabit: habits.firstWhere((h) => h.id == id),
        wasCompleted: wasCompleted,
        isCompleted: isNowCompleted,
        daySimple: daySimple,
        todaySimple: todaySimple,
      );
      if (daySimple != todaySimple) {
        context.read<StateProvider>().shouldUpdateStreaks = true;
      }
    }

    if (context.mounted) checkReorderCategories(context, habit);

    await updateHabitInDB(habit, day: daySimple);
    await _syncNotificationsOnCompletionChange(
      habit: habit,
      wasCompleted: wasCompleted,
      isNowCompleted: isNowCompleted,
      daySimple: daySimple,
      todaySimple: todaySimple,
    );
    _refreshPerfectStreakForDayIfNeeded(daySimple);
    if (wasCompleted != isNowCompleted && daySimple != todaySimple) {
      await assignStreaks(id);
    }
    refreshTodaysHabits(notify: false);
    notifyListeners();

    if (!wasCompleted && isNowCompleted) {
      _maybeCelebratePastDayStreak(context, daySimple, todaySimple);
    }
  }

  /// Whether [day] already has a snapshot with habits in it.
  bool hasRecordedDay(DateTime day) =>
      daysBox.get(_dayKeyOf(_normalizeDate(day)))?.habits.isNotEmpty ?? false;

  Future<void> saveHabitDay(
    DateTime day, {
    bool resetCompletion = false,
    bool isAutoCreated = false,
  }) async {
    habitStatsProvider?.clearAll();
    final daySimple = DateTime(day.year, day.month, day.day);
    final String dayKey = daySimple.toIso8601String().split('T').first;
    debugPrint("Saving day at: $daySimple");

    late final List<Habit> clonedHabits;

    if (resetCompletion) {
      clonedHabits = habits.map((h) => h.copyResetCompletion()).toList();
    } else {
      clonedHabits = habits.map((h) => h.forDay()).toList();
    }

    final scheduledForDay = _scheduledHabitsForDaySnapshot(
      daySimple,
      clonedHabits,
    );

    debugPrint(
      "[DAYSAVE] $dayKey resetCompletion=$resetCompletion "
      "autoCreated=$isAutoCreated live=${habits.length} "
      "scheduled=${scheduledForDay.length} "
      "existing=${daysBox.get(dayKey)?.habits.length}",
    );

    daysBox.put(
      dayKey,
      Day(
        date: daySimple,
        habits: scheduledForDay,
        timestamp: DateTime.now().toUtc(),
        isAutoCreated: isAutoCreated,
      ),
    );
  }

  bool _isRecalculatingLongestStreak = false;
  bool get isRecalculatingLongestStreak => _isRecalculatingLongestStreak;

  // Counts completions for the support banner's "10 completions" threshold. The
  // review prompt no longer fires here, it waits for a streak milestone.
  Future<void> _countCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(kTotalCompletionsKey) ?? 0) + 1;
    await prefs.setInt(kTotalCompletionsKey, count);
  }

  Future<void> recalculateLongestStreaks([int? onlyHabitId]) async {
    _isRecalculatingLongestStreak = true;
    notifyListeners();

    final sortedDays = daysBox.values.toList();
    sortedDays.sort((a, b) => a.date.compareTo(b.date)); // oldest → newest
    final today = _normalizeDate(DateTime.now());
    // Drop today and any future days (left behind if the device clock was
    // moved ahead and back), which would otherwise count as misses.
    sortedDays.removeWhere((day) => !_normalizeDate(day.date).isBefore(today));

    for (final habit in habitBox.values) {
      if (onlyHabitId != null && habit.id != onlyHabitId) continue;
      int longestStreak = 0;
      int currentRun = 0;
      int consecutiveMisses = 0;

      for (final day in sortedDays) {
        final normalizedDay = _normalizeDate(day.date);

        Habit? dayHabit;
        for (final candidate in day.habits) {
          if (candidate.id == habit.id) {
            dayHabit = candidate;
            break;
          }
        }
        if (dayHabit == null) continue;

        final appears = _appearedOnPastDay(habit, dayHabit, normalizedDay);
        if (!appears && !dayHabit.hasAnyProgress()) continue;

        if (dayHabit.completed) {
          currentRun++;
          consecutiveMisses = 0;
          if (currentRun > longestStreak) longestStreak = currentRun;
        } else {
          if (dayHabit.hasTrackingType) {
            if (dayHabit.tracksAmount && dayHabit.amountCompleted > 0) {
              consecutiveMisses = 0;
              continue;
            } else if (dayHabit.tracksDuration &&
                dayHabit.durationCompleted > 0) {
              consecutiveMisses = 0;
              continue;
            }
          }
          consecutiveMisses++;
          if (consecutiveMisses >= 3) {
            currentRun = 0;
            consecutiveMisses = 0;
          }
        }
      }

      habit.setLongestStreak(longestStreak);
      await habit.save();
    }

    _isRecalculatingLongestStreak = false;
    notifyListeners();
  }

  Future<void> assignStreaks([int? onlyHabitId]) async {
    // debugPrint("Assigning streaks");

    final sortedDays = daysBox.values.toList();
    // Getting all days from the database and sorting them from newest to oldest
    sortedDays.sort((a, b) => b.date.compareTo(a.date));

    final today = _normalizeDate(DateTime.now());
    // Removing today and any future days (left behind if the device clock was
    // moved ahead and back), which would otherwise count as misses.
    sortedDays.removeWhere((day) => !_normalizeDate(day.date).isBefore(today));

    final currentHabits = habitBox.values;

    for (final habit in currentHabits) {
      if (onlyHabitId != null && habit.id != onlyHabitId) {
        continue;
      }
      // debugPrint("Checking habit: ${habit.name}");

      int streak = 0;
      int longestStreak = habit.longestStreak;
      int consecutiveMisses = 0;

      // Misses since the most recent day that reset tolerance, stopped counting after 3 consecutive misses
      int tailMisses = 0;
      bool tailSettled = false;

      for (final day in sortedDays) {
        final normalizedDay = _normalizeDate(day.date);

        Habit? dayHabit;
        // We get the correct habit
        for (final candidate in day.habits) {
          if (candidate.id == habit.id) {
            dayHabit = candidate;
            break;
          }
        }

        if (dayHabit == null) {
          continue;
        }

        final appears = _appearedOnPastDay(habit, dayHabit, normalizedDay);
        if (!appears && !dayHabit.hasAnyProgress()) {
          // If it doesn't appear on this day and has no progress, we skip
          // it, it doesn't affect the streak
          continue;
        }

        // If it's completed we reset misses counter and increase streak
        if (dayHabit.completed) {
          streak++;
          consecutiveMisses = 0;
          tailSettled = true;
          if (streak >= longestStreak) {
            longestStreak = streak;
          }
        } else {
          // If it doesn't have any progress we increment misses counter

          if (dayHabit.hasTrackingType) {
            if (dayHabit.tracksAmount) {
              if (dayHabit.amountCompleted > 0) {
                continue;
              }
            } else if (dayHabit.tracksDuration) {
              if (dayHabit.durationCompleted > 0) {
                continue;
              }
            }
          }

          consecutiveMisses++;
          if (!tailSettled) tailMisses++;
          if (consecutiveMisses >= 3) {
            // If there are 3 or more consecutive misses, we break the loop
            break;
          }
        }
      }

      _habitConsecutiveMisses[habit.id] = tailMisses;
      habit.updateStreak(streak: streak, longestStreak: longestStreak);
      // debugPrint("Streak: $streak, Longest Streak: $longestStreak");
      await habit.save();
    }

    notifyListeners();
  }

  Future<void> recalculateHabitStreaks(int habitId) async {
    await assignStreaks(habitId);
  }
}
