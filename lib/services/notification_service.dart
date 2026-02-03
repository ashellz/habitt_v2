import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/notifications_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Request notification permissions
  static Future<bool> requestPermissions(BuildContext context) async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      final allowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
      return allowed;
    }
    return true;
  }

  /// Check if notifications are allowed
  static Future<bool> areNotificationsAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Schedule all enabled notifications based on provider settings
  static Future<void> scheduleAllNotifications(
    NotificationsProvider provider,
  ) async {
    // Cancel all existing notifications first
    await AwesomeNotifications().cancelAll();

    for (final period in NotificationPeriod.values) {
      final settings = provider.getSettings(period);

      if (settings.enabled) {
        await _schedulePeriodNotifications(period, settings);
      }
    }
  }

  /// Schedule notifications for a specific period
  static Future<void> _schedulePeriodNotifications(
    NotificationPeriod period,
    NotificationSettings settings,
  ) async {
    for (final weekday in settings.weekdays) {
      final notificationId = _getNotificationId(period, weekday);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'basic_channel',
          title: 'Habitt',
          body: period.notificationMessage,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          hour: settings.time.hour,
          minute: settings.time.minute,
          second: 0,
          millisecond: 0,
          weekday: weekday,
          repeats: true,
          allowWhileIdle: true,
        ),
      );

      debugPrint(
        'Scheduled ${period.name} notification for weekday $weekday at ${settings.time.hour}:${settings.time.minute}',
      );
    }
  }

  /// Cancel notifications for a specific period
  static Future<void> cancelPeriodNotifications(
    NotificationPeriod period,
  ) async {
    for (int weekday = 1; weekday <= 7; weekday++) {
      final notificationId = _getNotificationId(period, weekday);
      await AwesomeNotifications().cancel(notificationId);
    }
    debugPrint('Cancelled all ${period.name} notifications');
  }

  /// Reschedule a specific period's notifications
  static Future<void> reschedulePeriod(
    NotificationPeriod period,
    NotificationsProvider provider,
  ) async {
    await cancelPeriodNotifications(period);

    final settings = provider.getSettings(period);
    if (settings.enabled) {
      await _schedulePeriodNotifications(period, settings);
    }
  }

  /// Generate unique notification ID for period + weekday combination
  /// Format: period_index * 10 + weekday (e.g., morning=0, monday=1 -> ID: 1)
  static int _getNotificationId(NotificationPeriod period, int weekday) {
    return period.index * 10 + weekday;
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    debugPrint('Cancelled all notifications');
  }

  /// List all scheduled notifications (for debugging)
  static Future<List<NotificationModel>> listScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }
}
