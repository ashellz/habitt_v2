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
}

class NotificationsProvider extends ChangeNotifier {
  bool notificationsEnabled = false;
}
