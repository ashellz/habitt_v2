import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/services/health_service.dart';

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
        final value = await _service.fetchValueForDay(
          metric,
          targetDay,
          trackingType: habit.trackingType,
          workoutFilter: habit.healthWorkoutFilter,
        );
        if (value == null) continue;
        final sessions = await _service.fetchSessionsForDay(
          metric,
          targetDay,
          workoutFilter: habit.healthWorkoutFilter,
        );
        await habitProvider.syncHabitFromHealth(
          habit.id,
          metric,
          value,
          day: targetDay,
          sessions: sessions,
        );
      }
      lastSyncedAt = DateTime.now();
    } catch (_) {
      // A Health read failure must never block app-open flow.
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }
}
