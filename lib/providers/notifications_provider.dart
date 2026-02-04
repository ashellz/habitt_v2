import 'package:flutter/material.dart';
import 'package:habitt/models/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // Settings for each period
  final Map<NotificationPeriod, NotificationSettings> _settings = {
    NotificationPeriod.morning: NotificationSettings.defaultForPeriod(
      NotificationPeriod.morning,
    ),
    NotificationPeriod.afternoon: NotificationSettings.defaultForPeriod(
      NotificationPeriod.afternoon,
    ),
    NotificationPeriod.evening: NotificationSettings.defaultForPeriod(
      NotificationPeriod.evening,
    ),
  };

  NotificationsProvider(SharedPreferences prefs) {
    _prefs = prefs;
    _loadSettings();
  }

  /// Load settings from SharedPreferences
  void _loadSettings() {
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
  }

  // Getters
  NotificationSettings getSettings(NotificationPeriod period) {
    return _settings[period] ?? NotificationSettings.defaultForPeriod(period);
  }

  bool isEnabled(NotificationPeriod period) {
    return _settings[period]?.enabled ?? false;
  }

  TimeOfDay getTime(NotificationPeriod period) {
    return _settings[period]?.time ?? period.defaultTime;
  }

  Set<int> getWeekdays(NotificationPeriod period) {
    return _settings[period]?.weekdays ?? {1, 2, 3, 4, 5, 6, 7};
  }

  /// Check if any notification is enabled
  bool get hasAnyEnabled {
    return _settings.values.any((settings) => settings.enabled);
  }

  // Setters
  Future<void> toggleEnabled(NotificationPeriod period) async {
    final current = _settings[period]!;
    _settings[period] = current.copyWith(enabled: !current.enabled);
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
}
