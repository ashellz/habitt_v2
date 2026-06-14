import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/notification.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/services/habit_notification_text_builder.dart';
import 'package:habitt/services/notification_text/locale_resolver.dart';
import 'package:habitt/util/custom_amount_label.dart';

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
    int horizonDays = 7,
    bool skipToday = false,
  }) async {
    final allowed = await areNotificationsAllowed();
    if (!allowed) {
      debugPrint(
        "[NOTIFICATIONS] Skipping habit notification sync because no permissions",
      );
      return;
    }

    await cancelHabitNotifications(habit, horizonDays: horizonDays);
    final localizations =
        await HabitNotificationLocaleResolver.resolveFromPreferences();
    final customSingulars =
        await CustomAmountLabel.loadCustomSingularsFromPrefs();
    debugPrint(
      "[NOTIFICATIONS] Rescheduling notifications for habit ${habit.name} over next $horizonDays days (skipToday: $skipToday)",
    );
    await _scheduleHabitNotifications(
      habit: habit,
      appearsOnDay: appearsOnDay,
      horizonDays: horizonDays,
      localizations: localizations,
      customSingulars: customSingulars,
      startDayOffset: skipToday ? 1 : 0,
    );
  }

  static Future<void> scheduleAllHabitNotifications({
    required Iterable<Habit> habits,
    required bool Function(Habit habit, DateTime day) appearsOnDay,
    int horizonDays = 7,
  }) async {
    final allowed = await areNotificationsAllowed();
    if (!allowed) {
      return;
    }

    // Cancel existing notifications by deterministic IDs instead of using the
    // expensive listScheduledNotifications() platform call. Since IDs are computed
    // from habitId × slotId × day, we can cancel exactly the right set without
    // fetching anything from the platform first.
    // Note: notification slots removed from a habit since the last sync are
    // non-repeating, so any orphaned entries fire at most once then disappear.
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);
    for (final habit in habits) {
      if (habit.notificationTimes.isEmpty) continue;
      for (int dayOffset = 0; dayOffset < horizonDays; dayOffset++) {
        final day = startDay.add(Duration(days: dayOffset));
        for (final slot in habit.notificationTimes) {
          await AwesomeNotifications().cancel(
            _getHabitNotificationId(habit.id, slot.id, day),
          );
        }
      }
    }

    final localizations =
        await HabitNotificationLocaleResolver.resolveFromPreferences();
    final customSingulars =
        await CustomAmountLabel.loadCustomSingularsFromPrefs();

    // debugPrint('Scheduling notifications for ${habits.length} habits over next $horizonDays days',);
    for (final habit in habits) {
      //debugPrint('Scheduling notifications for habit ${habit.name}');
      await _scheduleHabitNotifications(
        habit: habit,
        appearsOnDay: appearsOnDay,
        horizonDays: horizonDays,
        localizations: localizations,
        customSingulars: customSingulars,
      );
    }

    debugPrint('Scheduled notifications for all habits');
  }

  static Future<void> _scheduleHabitNotifications({
    required Habit habit,
    required bool Function(Habit habit, DateTime day) appearsOnDay,
    required int horizonDays,
    required AppLocalizations localizations,
    Map<String, String>? customSingulars,
    int startDayOffset = 0,
  }) async {
    if (habit.isDeleted == true ||
        !habit.notificationsEnabled ||
        habit.notificationTimes.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);

    for (
      int dayOffset = startDayOffset;
      dayOffset < horizonDays + startDayOffset;
      dayOffset++
    ) {
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
        final text = HabitNotificationTextBuilder.build(
          HabitNotificationContext(
            habit: habit,
            scheduledAt: scheduledAt,
            appearsOnDay: appearsOnDay,
            localizations: localizations,
            now: now,
            customSingulars: customSingulars,
          ),
        );

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: 'basic_channel',
            title: text.title,
            body: text.description,
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

  // Cancels notifications for a specific habit using deterministic ID computation,
  // avoiding the expensive listScheduledNotifications() platform call.
  // Note: notifications for removed slots are cleaned up by scheduleAllHabitNotifications on app init.
  static Future<void> cancelHabitNotifications(
    Habit habit, {
    int horizonDays = 7,
  }) async {
    if (habit.notificationTimes.isEmpty) return;
    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);
    for (int dayOffset = 0; dayOffset < horizonDays; dayOffset++) {
      final day = startDay.add(Duration(days: dayOffset));
      for (final slot in habit.notificationTimes) {
        final id = _getHabitNotificationId(habit.id, slot.id, day);
        await AwesomeNotifications().cancel(id);
      }
    }
  }

  // Cancels only the notification slots for a single day. Used when a habit is
  // completed today and its future schedule is unaffected (daily habits).
  static Future<void> cancelHabitNotificationsForDay(
    Habit habit,
    DateTime day,
  ) async {
    if (habit.notificationTimes.isEmpty) return;
    final normalizedDay = DateTime(day.year, day.month, day.day);
    for (final slot in habit.notificationTimes) {
      final id = _getHabitNotificationId(habit.id, slot.id, normalizedDay);
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
