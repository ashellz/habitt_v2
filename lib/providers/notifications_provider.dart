import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/models/habit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitt/services/notification_service.dart';

class NotificationsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // Global toggles
  bool _masterEnabled = true; // master toggle - disables everything when false
  bool _periodsEnabled =
      true; // enables/disables period (morning/afternoon/evening) notifications
  bool _habitsEnabled = true; // enables/disables habit notifications

  static const String _masterKey = 'notifications_master_enabled';
  static const String _periodsKey = 'notifications_periods_enabled';
  static const String _habitsKey = 'notifications_habits_enabled';

  // Settings for each period
  final Map<NotificationPeriod, NotificationSettings> _settings = {
    NotificationPeriod.morning: NotificationSettings.defaultForPeriod(
      NotificationPeriod.morning,
    ),
    NotificationPeriod.midday: NotificationSettings.defaultForPeriod(
      NotificationPeriod.midday,
    ),
    NotificationPeriod.wrapUp: NotificationSettings.defaultForPeriod(
      NotificationPeriod.wrapUp,
    ),
  };

  NotificationsProvider(SharedPreferences prefs) {
    _prefs = prefs;
    _loadSettings();
    unawaited(_syncPermissionStateOnInit());
  }

  Future<void> _syncPermissionStateOnInit() async {
    final allowed = await NotificationService.areNotificationsAllowed();
    if (allowed) return;

    _masterEnabled = false;
    _periodsEnabled = false;
    _habitsEnabled = false;

    for (final period in NotificationPeriod.values) {
      final current = _settings[period]!;
      _settings[period] = current.copyWith(enabled: false);
      await _prefs?.setString(
        'notification_${period.name}',
        'enabled=false&hour=${current.time.hour}&minute=${current.time.minute}&weekdays=${current.weekdays.join(',')}',
      );
    }

    await _prefs?.setBool(_masterKey, false);
    await _prefs?.setBool(_periodsKey, false);
    await _prefs?.setBool(_habitsKey, false);
    await NotificationService.cancelAllNotifications();
    await NotificationService.cancelAllHabitNotifications();
    notifyListeners();
  }

  Future<bool> _enableReminderGates(
    BuildContext context, {
    required bool enablePeriods,
    required bool enableHabits,
  }) async {
    final allowed = await NotificationService.requestPermissions(context);
    if (!allowed) return false;

    if (!_masterEnabled) {
      _masterEnabled = true;
      await _prefs?.setBool(_masterKey, true);
    }

    if (!_periodsEnabled && enablePeriods) {
      _periodsEnabled = true;
      await _prefs?.setBool(_periodsKey, true);
    }

    if (!_habitsEnabled && enableHabits) {
      _habitsEnabled = true;
      await _prefs?.setBool(_habitsKey, true);
    }

    return true;
  }

  Future<void> _disableAllPeriodReminders() async {
    for (final period in NotificationPeriod.values) {
      final current = _settings[period]!;
      if (!current.enabled) continue;

      _settings[period] = current.copyWith(enabled: false);
      await _saveSettings(period);
    }
  }

  /// Load settings from SharedPreferences
  void _loadSettings() {
    // Load global toggles first
    _masterEnabled = _prefs?.getBool(_masterKey) ?? true;
    _periodsEnabled = _prefs?.getBool(_periodsKey) ?? true;
    _habitsEnabled = _prefs?.getBool(_habitsKey) ?? true;

    for (final period in NotificationPeriod.values) {
      final key = 'notification_${period.name}';
      final jsonString = _prefs?.getString(key);
      if (jsonString != null) {
        try {
          // Mapping data to json
          final json = Map<String, dynamic>.from(
            // Splitting the query string into key-value pairs
            // This function goes through every key-value pair in the string
            // splitQueryString is used to split string key-value pairs by '&' and '='
            Uri.splitQueryString(jsonString).map((key, value) {
              // Parse the stored format back to proper types
              if (key == 'enabled') return MapEntry(key, value == 'true');
              if (key == 'hour' || key == 'minute') {
                return MapEntry(key, int.parse(value));
              }
              if (key == 'weekdays') {
                return MapEntry(key, value.split(',').map(int.parse).toList());
              }
              return MapEntry(key, value);
            }),
          );
          // Applying the mapped json to NotificationSettings by period
          _settings[period] = NotificationSettings.fromJson(json);
        } catch (e) {
          debugPrint('Error loading notification settings for $period: $e');
        }
      }
    }
    notifyListeners();
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings(NotificationPeriod period) async {
    final settings = _settings[period]!;
    final key = 'notification_${period.name}';

    // Simple string-based storage
    // & is a separator between key-value pairs
    final data =
        'enabled=${settings.enabled}'
        '&hour=${settings.time.hour}'
        '&minute=${settings.time.minute}'
        '&weekdays=${settings.weekdays.join(',')}';

    await _prefs?.setString(key, data);

    // If master or period notifications are disabled, ensure scheduled notifications for this period are cancelled
    if (!_masterEnabled || !_periodsEnabled || !settings.enabled) {
      await NotificationService.cancelPeriodNotifications(period);
    } else {
      // Reschedule this period according to the new settings
      await NotificationService.reschedulePeriod(period, this);
    }
  }

  // Getters
  NotificationSettings getSettings(NotificationPeriod period) {
    return _settings[period] ?? NotificationSettings.defaultForPeriod(period);
  }

  bool isEnabled(NotificationPeriod period) {
    // Respect global toggles: master and period notifications must be enabled
    return _masterEnabled &&
        _periodsEnabled &&
        (_settings[period]?.enabled ?? false);
  }

  TimeOfDay getTime(NotificationPeriod period) {
    return _settings[period]?.time ?? period.defaultTime;
  }

  Set<int> getWeekdays(NotificationPeriod period) {
    return _settings[period]?.weekdays ?? {1, 2, 3, 4, 5, 6, 7};
  }

  /// Check if any notification is enabled
  bool get hasAnyEnabled {
    if (!_masterEnabled) return false;

    final periodsAny =
        _periodsEnabled && _settings.values.any((settings) => settings.enabled);
    // If habit notifications are enabled we consider there may be enabled habit notifications
    final habitsAny = _habitsEnabled;
    return periodsAny || habitsAny;
  }

  // Setters
  Future<void> toggleEnabled(
    NotificationPeriod period,
    BuildContext context,
  ) async {
    final current = _settings[period]!;
    final enabling = !current.enabled;

    if (enabling) {
      final allowed = await _enableReminderGates(
        context,
        enablePeriods: true,
        enableHabits: false,
      );
      if (!allowed) return;
    }

    _settings[period] = current.copyWith(enabled: enabling);
    await _saveSettings(period);
    notifyListeners();
  }

  Future<void> setTime(NotificationPeriod period, TimeOfDay time) async {
    // Validate time is within period range
    if (!period.isTimeInRange(time)) {
      debugPrint(
        'Warning: Time ${time.hour}:${time.minute} is outside ${period.name} range',
      );
      return;
    }

    final current = _settings[period]!;
    _settings[period] = current.copyWith(time: time);
    await _saveSettings(period);
    notifyListeners();
  }

  Future<void> toggleWeekday(NotificationPeriod period, int weekday) async {
    final current = _settings[period]!;
    final newWeekdays = Set<int>.from(current.weekdays);

    if (newWeekdays.contains(weekday)) {
      newWeekdays.remove(weekday);
    } else {
      newWeekdays.add(weekday);
    }

    // Don't allow removing all days
    if (newWeekdays.isEmpty) return;

    _settings[period] = current.copyWith(weekdays: newWeekdays);
    await _saveSettings(period);
    notifyListeners();
  }

  Future<void> setWeekdays(NotificationPeriod period, Set<int> weekdays) async {
    if (weekdays.isEmpty) return; // Don't allow empty weekdays

    final current = _settings[period]!;
    _settings[period] = current.copyWith(weekdays: weekdays);
    await _saveSettings(period);
    notifyListeners();
  }

  /// Replace the full settings for a period and persist.
  Future<void> setSettings(
    NotificationPeriod period,
    NotificationSettings settings,
  ) async {
    _settings[period] = settings;
    await _saveSettings(period);
    notifyListeners();
  }

  // --- Global toggles API ---

  /// Master toggle: when false disables all notifications (periods + habits)
  bool get isMasterEnabled => _masterEnabled;

  Future<void> toggleMasterEnabled(BuildContext context) async {
    final enabling = !_masterEnabled;

    if (enabling) {
      final allowed = await NotificationService.requestPermissions(context);
      if (!allowed) return;
    }

    _masterEnabled = enabling;
    await _prefs?.setBool(_masterKey, _masterEnabled);

    if (!_masterEnabled) {
      _periodsEnabled = false;
      _habitsEnabled = false;
      await _prefs?.setBool(_periodsKey, false);
      await _prefs?.setBool(_habitsKey, false);

      await _disableAllPeriodReminders();

      await NotificationService.cancelAllNotifications();
      await NotificationService.cancelAllHabitNotifications();
    } else {
      // Reschedule period notifications according to current settings
      await NotificationService.scheduleAllNotifications(this);

      // If habit notifications are enabled, attempt to schedule them when caller provides habits
      // (caller can pass habits + appearsOnDay to this method).
    }

    notifyListeners();
  }

  /// Periods toggle: enable/disable morning/afternoon/evening notifications
  bool get arePeriodNotificationsEnabled => _periodsEnabled;

  Future<void> togglePeriodNotifications(BuildContext context) async {
    final enabling = !_periodsEnabled;

    if (enabling) {
      final allowed = await _enableReminderGates(
        context,
        enablePeriods: true,
        enableHabits: false,
      );
      if (!allowed) return;
    }

    _periodsEnabled = enabling;
    await _prefs?.setBool(_periodsKey, _periodsEnabled);

    if (!_periodsEnabled) {
      await _disableAllPeriodReminders();

      await NotificationService.cancelAllNotifications();
    } else {
      await NotificationService.scheduleAllNotifications(this);
    }

    notifyListeners();
  }

  /// Habits toggle: enable/disable habit-generated notifications globally
  bool get areHabitNotificationsEnabled => _habitsEnabled;

  Future<void> toggleHabitNotifications({
    required BuildContext context,
    Iterable<Habit>? habits,
    bool Function(Habit, DateTime)? appearsOnDay,
    int horizonDays = 90,
  }) async {
    final enabling = !_habitsEnabled;

    if (enabling) {
      final allowed = await _enableReminderGates(
        context,
        enablePeriods: false,
        enableHabits: true,
      );
      if (!allowed) return;
    }

    _habitsEnabled = enabling;
    await _prefs?.setBool(_habitsKey, _habitsEnabled);

    if (!_habitsEnabled) {
      await NotificationService.cancelAllHabitNotifications();
    } else {
      if (!_masterEnabled) {
        debugPrint(
          'Master notifications disabled; habit notifications will not be scheduled until master is enabled.',
        );
      } else if (habits != null && appearsOnDay != null) {
        await NotificationService.scheduleAllHabitNotifications(
          habits: habits,
          appearsOnDay: appearsOnDay,
          horizonDays: horizonDays,
        );
      } else {
        debugPrint(
          'Habits enabled but no habits/appearsOnDay provided; caller must schedule habit notifications.',
        );
      }
    }

    notifyListeners();
  }

  /// Apply all global notification toggles in one transaction.
  ///
  /// Returns false when enabling requires permission and the user denies it.
  Future<bool> applyGlobalToggles({
    required BuildContext context,
    required bool masterEnabled,
    required bool periodsEnabled,
    required bool habitsEnabled,
    Iterable<Habit>? habits,
    bool Function(Habit, DateTime)? appearsOnDay,
    int horizonDays = 90,
  }) async {
    final previousMasterEnabled = _masterEnabled;
    final previousPeriodsEnabled = _periodsEnabled;
    final previousHabitsEnabled = _habitsEnabled;

    final previousEffectivePeriods =
        previousMasterEnabled && previousPeriodsEnabled;
    final previousEffectiveHabits =
        previousMasterEnabled && previousHabitsEnabled;

    final effectivePeriods = masterEnabled && periodsEnabled;
    final effectiveHabits = masterEnabled && habitsEnabled;

    final needsPermission =
        (!previousMasterEnabled && masterEnabled) ||
        (!previousEffectivePeriods && effectivePeriods) ||
        (!previousEffectiveHabits && effectiveHabits);

    if (needsPermission) {
      final allowed = await NotificationService.requestPermissions(context);
      if (!allowed) {
        return false;
      }
    }

    _masterEnabled = masterEnabled;
    _periodsEnabled = periodsEnabled;
    _habitsEnabled = habitsEnabled;

    if (!_masterEnabled) {
      _periodsEnabled = false;
      _habitsEnabled = false;
    }

    await _prefs?.setBool(_masterKey, _masterEnabled);
    await _prefs?.setBool(_periodsKey, _periodsEnabled);
    await _prefs?.setBool(_habitsKey, _habitsEnabled);

    final currentEffectivePeriods = _masterEnabled && _periodsEnabled;
    final currentEffectiveHabits = _masterEnabled && _habitsEnabled;

    if (previousMasterEnabled != _masterEnabled) {
      if (!_masterEnabled) {
        await _disableAllPeriodReminders();
        await NotificationService.cancelAllNotifications();
        await NotificationService.cancelAllHabitNotifications();
      } else {
        if (currentEffectivePeriods) {
          await NotificationService.scheduleAllNotifications(this);
        }

        if (currentEffectiveHabits && habits != null && appearsOnDay != null) {
          await NotificationService.scheduleAllHabitNotifications(
            habits: habits,
            appearsOnDay: appearsOnDay,
            horizonDays: horizonDays,
          );
        } else if (currentEffectiveHabits) {
          debugPrint(
            'Habits enabled but no habits/appearsOnDay provided; caller must schedule habit notifications.',
          );
        }
      }
    } else {
      if (previousEffectivePeriods != currentEffectivePeriods) {
        if (currentEffectivePeriods) {
          await NotificationService.scheduleAllNotifications(this);
        } else {
          await _disableAllPeriodReminders();
          await NotificationService.cancelAllNotifications();
        }
      }

      if (previousEffectiveHabits != currentEffectiveHabits) {
        if (currentEffectiveHabits && habits != null && appearsOnDay != null) {
          await NotificationService.scheduleAllHabitNotifications(
            habits: habits,
            appearsOnDay: appearsOnDay,
            horizonDays: horizonDays,
          );
        } else {
          await NotificationService.cancelAllHabitNotifications();
          if (currentEffectiveHabits) {
            debugPrint(
              'Habits enabled but no habits/appearsOnDay provided; caller must schedule habit notifications.',
            );
          }
        }
      }
    }

    notifyListeners();
    return true;
  }
}
