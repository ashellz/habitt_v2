import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/services/health_service.dart';
import 'package:habitt/util/health_sync_range.dart';
import 'package:habitt/util/health_value_guard.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLastSyncedAtKey = 'healthLastSyncedAt';

// habit id -> the last day (yyyy-MM-dd) its Health sync reached, JSON encoded.
// Lives in SharedPreferences like lastSyncedAt: it is sync bookkeeping, not
// habit data, so it stays out of Hive and the backup/merge system.
const String _kSyncCursorsKey = 'healthSyncCursors';

class HealthProvider extends ChangeNotifier {
  HealthProvider({HealthService? service})
    : _service = service ?? HealthService();

  final HealthService _service;
  HabitProvider? _habitProvider;

  bool isAvailable = false;
  bool permissionGranted = false;
  bool isSyncing = false;
  DateTime? lastSyncedAt;
  bool _availabilityChecked = false;
  bool _iosAccessRequested = false;

  List<HealthMetricType> get supportedMetrics => _service.supportedMetrics;

  bool isMetricSupported(HealthMetricType metric) =>
      _service.isMetricSupported(metric);

  void attachHabitProvider(HabitProvider habitProvider) {
    _habitProvider = habitProvider;
  }

  Future<void> ensureAvailabilityChecked() async {
    if (_availabilityChecked) return;
    _availabilityChecked = true;
    await _loadLastSyncedAt();
    try {
      isAvailable = await _service.isAvailable();
      if (isAvailable) {
        permissionGranted = await _service.hasPermissions();
      }
    } catch (_) {
      isAvailable = false;
    }
    notifyListeners();
  }

  // lastSyncedAt only lives in memory otherwise, so the details card would
  // read "not synced yet" after every restart until the next sync finishes
  Future<void> _loadLastSyncedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_kLastSyncedAtKey);
      if (ms != null && lastSyncedAt == null) {
        lastSyncedAt = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (_) {
      // a missing timestamp just shows as "not synced yet"
    }
  }

  Future<void> _saveLastSyncedAt(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastSyncedAtKey, time.millisecondsSinceEpoch);
    } catch (_) {
      // losing the timestamp is harmless
    }
  }


  String _dayKey(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().split('T').first;

  Future<Map<int, DateTime>> _loadCursors() async {
    final cursors = <int, DateTime>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSyncCursorsKey);
      if (raw == null) return cursors;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return cursors;
      decoded.forEach((key, value) {
        final id = int.tryParse(key.toString());
        final day = DateTime.tryParse(value.toString());
        if (id != null && day != null) {
          cursors[id] = DateTime(day.year, day.month, day.day);
        }
      });
    } catch (_) {
      // a lost cursor only means no catch-up until the next sync sets it
    }
    return cursors;
  }

  Future<void> _saveCursors(Map<int, DateTime> cursors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kSyncCursorsKey,
        jsonEncode({
          for (final e in cursors.entries) e.key.toString(): _dayKey(e.value),
        }),
      );
    } catch (_) {
      // losing the cursor is harmless, see _loadCursors
    }
  }

  // used when user tries to link a habit to Health for the first ime
  Future<bool> requestPermissionIfNeeded() async {
    await ensureAvailabilityChecked();
    if (!isAvailable) return false;
    try {
      final granted = await _service.requestAuthorization();
      permissionGranted = granted;
      notifyListeners();
      return granted;
    } catch (_) {
      return false;
    }
  }

  // used every time app is opened to sync health data to habits.
  // Each habit also catches up on the days since its last sync (at most
  // kHealthBackfillMaxDays), see _catchUpHabit.
  Future<void> syncNow({DateTime? day}) async {
    if (isSyncing) return;
    final habitProvider = _habitProvider;
    if (habitProvider == null) return;

    final linkedHabits =
        habitProvider.habits
            .where(
              (h) =>
                  h.healthMetric != null &&
                  h.isDeleted != true &&
                  h.isPaused != true,
            )
            .toList();

    // a habit that is unlinked, deleted or paused loses its cursor, so when it
    // comes back it starts from that day instead of backfilling the gap
    final cursors = await _loadCursors();
    final loadedCursors = Map<int, DateTime>.of(cursors);
    final linkedIds = linkedHabits.map((h) => h.id).toSet();
    final before = cursors.length;
    cursors.removeWhere((id, _) => !linkedIds.contains(id));
    if (cursors.length != before) await _saveCursors(cursors);

    if (linkedHabits.isEmpty) return;

    await ensureAvailabilityChecked();
    if (!isAvailable) return;

    // android is reliable, ios can give false even if okay so this is required
    if (Platform.isAndroid && !permissionGranted) return;

    final targetDay = day ?? DateTime.now();
    isSyncing = true;
    notifyListeners();

    try {
      await _requestIosAccessOnce(linkedHabits);
      for (final habit in linkedHabits) {
        cursors[habit.id] = await _catchUpHabit(
          habitProvider,
          habit,
          targetDay,
          cursors[habit.id],
        );
        // let the UI draw a frame between habits, a catch-up can be many reads
        await Future<void>.delayed(Duration.zero);
      }
      // most opens end on the cursors they started with, skip the write then
      if (!mapEquals(cursors, loadedCursors)) await _saveCursors(cursors);
      lastSyncedAt = DateTime.now();
      await _saveLastSyncedAt(lastSyncedAt!);
    } catch (_) {
      // A Health read failure must never block app-open flow.
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  // Syncs one habit's day (today, or yesterday for a "day before" bedtime)
  // first, then the days since [cursor], oldest to newest. Returns the new
  // cursor: the earliest day whose read failed, so it is tried again next
  // time, or the synced day when every read went through. The cursor day is
  // read again on the next run, which lets a night a watch uploaded late settle.
  Future<DateTime> _catchUpHabit(
    HabitProvider habitProvider,
    Habit habit,
    DateTime targetDay,
    DateTime? cursor,
  ) async {
    final metric = habit.healthMetric!;
    final syncDay = _service.syncDayFor(
      metric,
      targetDay,
      bedtimeDayBefore: habit.healthBedtimeDayBefore,
    );
    final days = healthCatchUpDays(
      syncDay: syncDay,
      cursor: cursor,
      floor: healthBackfillFloor(
        createdAt: habit.createdAt,
        pauseChangedAt: habit.timestamps['isPaused'],
      ),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? earliestFailure;
    var pastDayCompletionChanged = false;

    for (final d in days) {
      // no Health read for a day the habit isn't on
      if (d != syncDay && !habitProvider.canSyncHealthDay(habit.id, d)) {
        continue;
      }
      final isPast = d != today;
      final outcome = await _syncHabitDay(
        habitProvider,
        habit,
        d,
        refreshStreaks: !isPast,
      );
      if (outcome == null) {
        if (earliestFailure == null || d.isBefore(earliestFailure)) {
          earliestFailure = d;
        }
      } else if (isPast && outcome.completionChanged) {
        pastDayCompletionChanged = true;
      }
      if (days.length > 1) await Future<void>.delayed(Duration.zero);
    }

    // one streak pass for the whole catch-up, not one per day
    if (pastDayCompletionChanged) await habitProvider.assignStreaks(habit.id);

    return earliestFailure ?? syncDay;
  }

  // pulls Health progress for a single habit right away, so a habit that was
  // just created doesn't sit at 0 until the next app open. Safe while syncNow
  // is running: it only touches this habit.
  Future<void> syncHabit(Habit habit) async {
    final habitProvider = _habitProvider;
    final metric = habit.healthMetric;
    if (habitProvider == null || metric == null) return;

    try {
      await ensureAvailabilityChecked();
      if (!isAvailable) return;
      if (Platform.isAndroid && !permissionGranted) return;

      await _requestIosAccessOnce([habit]);
      final syncDay = _service.syncDayFor(
        metric,
        DateTime.now(),
        bedtimeDayBefore: habit.healthBedtimeDayBefore,
      );
      // the link day: later syncs catch up from here, never before it
      final cursors = await _loadCursors();
      if (!cursors.containsKey(habit.id)) {
        cursors[habit.id] = syncDay;
        await _saveCursors(cursors);
      }
      if (_countsAsSynced(await _syncHabitDay(habitProvider, habit, syncDay))) {
        lastSyncedAt = DateTime.now();
        await _saveLastSyncedAt(lastSyncedAt!);
        notifyListeners();
      }
    } catch (_) {
      // a Health read failure just leaves the habit for the next app-open sync
    }
  }

  Future<void> _requestIosAccessOnce(List<Habit> linkedHabits) async {
    if (!Platform.isIOS || _iosAccessRequested) return;
    final needsAccess = linkedHabits.any(
      (h) =>
          h.healthMetric == HealthMetricType.workouts ||
          h.healthMetric == HealthMetricType.activity,
    );
    if (!needsAccess) {
      return;
    }
    _iosAccessRequested = true;
    try {
      await _service.requestAuthorization();
    } catch (_) {
      // a denied or failed prompt just leaves the workouts read empty
    }
  }

  // disables manual override, then re-syncs the habit's day from Health to pull in its value
  // shows as a sync (syncing state, then fresh last-synced time) like syncNow does
  Future<void> useHealthValues(Habit habit, DateTime day) async {
    final habitProvider = _habitProvider;
    if (habitProvider == null || habit.healthMetric == null) return;

    await habitProvider.clearHealthManualOverride(habit.id, day: day);

    // a running syncNow already owns the syncing flag
    final ownsSyncingFlag = !isSyncing;
    try {
      await ensureAvailabilityChecked();
      if (!isAvailable) return;
      if (Platform.isAndroid && !permissionGranted) return;

      if (ownsSyncingFlag) {
        isSyncing = true;
        notifyListeners();
      }
      final applied = _countsAsSynced(
        await _syncHabitDay(habitProvider, habit, day),
      );
      if (applied) {
        lastSyncedAt = DateTime.now();
        await _saveLastSyncedAt(lastSyncedAt!);
      }
    } catch (_) {
      // the override is already cleared, so the next sync pulls the value in
    } finally {
      if (ownsSyncingFlag && isSyncing) {
        isSyncing = false;
        notifyListeners();
      }
    }
  }

  // whether a Health read gave something real: no value (a failed read) and a
  // discarded one (empty or corrupt) both leave the last-synced time alone
  bool _countsAsSynced(HealthApplyOutcome? outcome) =>
      outcome != null && outcome.status != HealthApplyStatus.discarded;

  // reads one Health value and its sessions for [syncDay] and applies them,
  // null if Health had no value to apply
  Future<HealthApplyOutcome?> _syncHabitDay(
    HabitProvider habitProvider,
    Habit habit,
    DateTime syncDay, {
    bool refreshStreaks = true,
  }) async {
    final metric = habit.healthMetric!;
    final bedtimeDayBefore = habit.healthBedtimeDayBefore;
    final reading = await _service.fetchDay(
      metric,
      syncDay,
      trackingType: habit.trackingType,
      workoutFilter: habit.healthWorkoutFilter,
      bedtimeDayBefore: bedtimeDayBefore,
    );
    if (reading == null) return null;
    return habitProvider.syncHabitFromHealth(
      habit.id,
      metric,
      reading.value,
      day: syncDay,
      sessions: reading.sessions,
      refreshStreaks: refreshStreaks,
    );
  }
}
