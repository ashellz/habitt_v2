import 'package:flutter/material.dart';

enum NotificationPeriod {
  morning,
  afternoon,
  evening;

  String get name {
    switch (this) {
      case NotificationPeriod.morning:
        return "Morning";
      case NotificationPeriod.afternoon:
        return "Afternoon";
      case NotificationPeriod.evening:
        return "Evening";
    }
  }

  /// Returns the hour range for this period (start inclusive, end exclusive)
  (int start, int end) get hourRange {
    switch (this) {
      case NotificationPeriod.morning:
        return (4, 12);
      case NotificationPeriod.afternoon:
        return (12, 19);
      case NotificationPeriod.evening:
        return (19, 24); // Note: evening wraps to next day at 4am
    }
  }

  /// Returns default notification time for this period
  TimeOfDay get defaultTime {
    switch (this) {
      case NotificationPeriod.morning:
        return const TimeOfDay(hour: 8, minute: 0);
      case NotificationPeriod.afternoon:
        return const TimeOfDay(hour: 15, minute: 0);
      case NotificationPeriod.evening:
        return const TimeOfDay(hour: 20, minute: 0);
    }
  }

  /// Returns notification message for this period
  String get notificationMessage {
    switch (this) {
      case NotificationPeriod.morning:
        return "Good morning! Time to check your habits";
      case NotificationPeriod.afternoon:
        return "Afternoon check-in time for your habits";
      case NotificationPeriod.evening:
        return "Evening reflection: How did your habits go today?";
    }
  }

  /// Validates if a time falls within this period's range
  bool isTimeInRange(TimeOfDay time) {
    final (start, end) = hourRange;
    if (this == NotificationPeriod.evening) {
      // Evening wraps around: 19-23 or 0-3
      return time.hour >= 19 || time.hour < 4;
    }
    return time.hour >= start && time.hour < end;
  }
}

class NotificationSettings {
  final bool enabled;
  final TimeOfDay time;
  final Set<int> weekdays; // 1 = Monday, 7 = Sunday

  NotificationSettings({
    required this.enabled,
    required this.time,
    required this.weekdays,
  });

  NotificationSettings copyWith({
    bool? enabled,
    TimeOfDay? time,
    Set<int>? weekdays,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'hour': time.hour,
      'minute': time.minute,
      'weekdays': weekdays.toList(),
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] as bool? ?? true,
      time: TimeOfDay(
        hour: json['hour'] as int? ?? 8,
        minute: json['minute'] as int? ?? 0,
      ),
      weekdays:
          (json['weekdays'] as List<dynamic>?)?.map((e) => e as int).toSet() ??
          {1, 2, 3, 4, 5, 6, 7},
    );
  }

  factory NotificationSettings.defaultForPeriod(NotificationPeriod period) {
    return NotificationSettings(
      enabled: true,
      time: period.defaultTime,
      weekdays: {1, 2, 3, 4, 5, 6, 7}, // All days by default
    );
  }
}
