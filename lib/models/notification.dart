import 'package:flutter/material.dart';

enum NotificationPeriod {
  morning,
  midday,
  wrapUp;

  String get name {
    switch (this) {
      case NotificationPeriod.morning:
        return "Morning";
      case NotificationPeriod.midday:
        return "Mid-day";
      case NotificationPeriod.wrapUp:
        return "Wrap up";
    }
  }

  String get iconPath {
    switch (this) {
      case NotificationPeriod.morning:
        return "assets/images/new-svg/morning.svg";
      case NotificationPeriod.midday:
        return "assets/images/new-svg/mid-day.svg";
      case NotificationPeriod.wrapUp:
        return "assets/images/new-svg/wrap-up.svg";
    }
  }

  /// Returns the hour range for this period (start inclusive, end exclusive)
  (int start, int end) get hourRange {
    switch (this) {
      case NotificationPeriod.morning:
        return (4, 12);
      case NotificationPeriod.midday:
        return (12, 19);
      case NotificationPeriod.wrapUp:
        return (19, 24); // Note: wrap-up wraps to next day at 4am
    }
  }

  /// Returns default notification time for this period
  TimeOfDay get defaultTime {
    switch (this) {
      case NotificationPeriod.morning:
        return const TimeOfDay(hour: 8, minute: 0);
      case NotificationPeriod.midday:
        return const TimeOfDay(hour: 15, minute: 0);
      case NotificationPeriod.wrapUp:
        return const TimeOfDay(hour: 20, minute: 0);
    }
  }

  /// Returns notification message for this period
  String get notificationMessage {
    switch (this) {
      case NotificationPeriod.morning:
        return "Good morning! Time to check your habits";
      case NotificationPeriod.midday:
        return "Mid-day check-in time for your habits";
      case NotificationPeriod.wrapUp:
        return "Wrap up reflection: How did your habits go today?";
    }
  }

  /// Validates if a time falls within this period's range
  bool isTimeInRange(TimeOfDay time) {
    final (start, end) = hourRange;
    if (this == NotificationPeriod.wrapUp) {
      // Wrap-up is around: 19-23 or 0-3
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
