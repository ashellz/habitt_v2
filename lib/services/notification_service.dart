import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/notifications_provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _habitPayloadKey = 'habit_id';
  static const String _habitPayloadTypeKey = 'notification_type';
  static const String _habitPayloadTypeValue = 'habit';

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
    await _cancelGlobalNotifications();

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

  static Future<void> _cancelGlobalNotifications() async {
    for (final period in NotificationPeriod.values) {
      for (int weekday = 1; weekday <= 7; weekday++) {
        final notificationId = _getNotificationId(period, weekday);
        await AwesomeNotifications().cancel(notificationId);
      }
    }
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

  static Future<void> rescheduleHabitNotifications({
    required Habit habit,
    required bool Function(Habit habit, DateTime day) appearsOnDay,
    int horizonDays = 90,
  }) async {
    final allowed = await areNotificationsAllowed();
    if (!allowed) {
      return;
    }

    await cancelHabitNotifications(habit.id);
    await _scheduleHabitNotifications(
      habit: habit,
      appearsOnDay: appearsOnDay,
      horizonDays: horizonDays,
    );
  }

  static Future<void> scheduleAllHabitNotifications({
    required Iterable<Habit> habits,
    required bool Function(Habit habit, DateTime day) appearsOnDay,
    int horizonDays = 90,
  }) async {
    final allowed = await areNotificationsAllowed();
    if (!allowed) {
      return;
    }

    await cancelAllHabitNotifications();

    for (final habit in habits) {
      await _scheduleHabitNotifications(
        habit: habit,
        appearsOnDay: appearsOnDay,
        horizonDays: horizonDays,
      );
    }
  }

  static Future<void> _scheduleHabitNotifications({
    required Habit habit,
    required bool Function(Habit habit, DateTime day) appearsOnDay,
    required int horizonDays,
  }) async {
    if (habit.isDeleted == true ||
        !habit.notificationsEnabled ||
        habit.notificationTimes.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);

    for (int dayOffset = 0; dayOffset < horizonDays; dayOffset++) {
      final day = startDay.add(Duration(days: dayOffset));
      if (!appearsOnDay(habit, day)) {
        continue;
      }

      for (final slot in habit.notificationTimes) {
        final hour = slot.minutesOfDay ~/ 60;
        final minute = slot.minutesOfDay % 60;
        final scheduledAt = DateTime(
          day.year,
          day.month,
          day.day,
          hour,
          minute,
        );

        if (!scheduledAt.isAfter(now)) {
          continue;
        }

        final notificationId = _getHabitNotificationId(habit.id, slot.id, day);

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: 'basic_channel',
            title: 'Habitt',
            body: 'Reminder: ${habit.name}',
            notificationLayout: NotificationLayout.Default,
            wakeUpScreen: true,
            category: NotificationCategory.Reminder,
            payload: {
              _habitPayloadKey: habit.id.toString(),
              _habitPayloadTypeKey: _habitPayloadTypeValue,
            },
          ),
          schedule: NotificationCalendar(
            year: day.year,
            month: day.month,
            day: day.day,
            hour: hour,
            minute: minute,
            second: 0,
            millisecond: 0,
            repeats: false,
            allowWhileIdle: true,
          ),
        );
      }
    }
  }

  static Future<void> cancelHabitNotifications(int habitId) async {
    final scheduled = await AwesomeNotifications().listScheduledNotifications();
    for (final model in scheduled) {
      final content = model.content;
      if (content == null) {
        continue;
      }

      final payload = content.payload;
      final isHabitNotification =
          payload?[_habitPayloadTypeKey] == _habitPayloadTypeValue;
      final belongsToHabit = payload?[_habitPayloadKey] == habitId.toString();
      if (!isHabitNotification || !belongsToHabit) {
        continue;
      }

      final id = content.id;
      if (id == null) {
        continue;
      }
      await AwesomeNotifications().cancel(id);
    }
  }

  static Future<void> cancelAllHabitNotifications() async {
    final scheduled = await AwesomeNotifications().listScheduledNotifications();
    for (final model in scheduled) {
      final content = model.content;
      if (content == null) {
        continue;
      }

      final payload = content.payload;
      final isHabitNotification =
          payload?[_habitPayloadTypeKey] == _habitPayloadTypeValue;
      if (!isHabitNotification) {
        continue;
      }

      final id = content.id;
      if (id == null) {
        continue;
      }
      await AwesomeNotifications().cancel(id);
    }
  }

  static int _getHabitNotificationId(int habitId, int slotId, DateTime day) {
    final dayKey = (day.year * 10000) + (day.month * 100) + day.day;
    final raw = (habitId * 31) ^ (slotId * 17) ^ dayKey;
    final normalized = raw.abs() % 900000000;
    return 1000000000 + normalized;
  }

  /// List all scheduled notifications (for debugging)
  static Future<List<NotificationModel>> listScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }
}
