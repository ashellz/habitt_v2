import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/services/health_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLastSyncedAtKey = 'healthLastSyncedAt';

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

  // used every time app is opened to sync health data to habits
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
    if (linkedHabits.isEmpty) return;

    await ensureAvailabilityChecked();
    if (!isAvailable) return;

    // android is reliable, ios can give false even if okay so this is required
    if (Platform.isAndroid && !permissionGranted) return;

    final targetDay = day ?? DateTime.now();
    isSyncing = true;
    notifyListeners();

    try {
      for (final habit in linkedHabits) {
        final metric = habit.healthMetric!;
        final syncDay = _service.syncDayFor(
          metric,
          targetDay,
          bedtimeDayBefore: habit.healthBedtimeDayBefore,
        );
        await _syncHabitDay(habitProvider, habit, syncDay);
      }
      lastSyncedAt = DateTime.now();
      await _saveLastSyncedAt(lastSyncedAt!);
    } catch (_) {
      // A Health read failure must never block app-open flow.
    } finally {
      isSyncing = false;
      notifyListeners();
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
      final applied = await _syncHabitDay(habitProvider, habit, day);
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

  // reads one Health value and its sessions for [syncDay] and applies them,
  // false if Health had no value to apply
  Future<bool> _syncHabitDay(
    HabitProvider habitProvider,
    Habit habit,
    DateTime syncDay,
  ) async {
    final metric = habit.healthMetric!;
    final bedtimeDayBefore = habit.healthBedtimeDayBefore;
    final value = await _service.fetchValueForDay(
      metric,
      syncDay,
      trackingType: habit.trackingType,
      workoutFilter: habit.healthWorkoutFilter,
      bedtimeDayBefore: bedtimeDayBefore,
    );
    if (value == null) return false;
    final sessions = await _service.fetchSessionsForDay(
      metric,
      syncDay,
      workoutFilter: habit.healthWorkoutFilter,
      bedtimeDayBefore: bedtimeDayBefore,
    );
    await habitProvider.syncHabitFromHealth(
      habit.id,
      metric,
      value,
      day: syncDay,
      sessions: sessions,
    );
    return true;
  }
}
