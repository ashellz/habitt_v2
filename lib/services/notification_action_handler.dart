import 'dart:ui' show DartPluginRegistrant;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habitt/pages/other_pages/habit_details_page.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/services/pending_completion_queue.dart';

@pragma('vm:entry-point')
class NotificationActionHandler {
  NotificationActionHandler._();

  static const String _payloadHabitIdKey = 'habit_id';
  static const String _payloadTypeKey = 'notification_type';
  static const String _payloadTypeHabit = 'habit';
  static const String _payloadDayKey = 'habit_day';

  /// Global navigator key so notifications can route without a widget context.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Set by the app (main isolate) to drain the pending-completion queue.
  /// Null in the background isolate, where we only enqueue.
  static Future<void> Function()? drainPending;

  /// Habit id captured before the navigator was ready (cold start). Consumed by
  /// [consumePendingRoute] once the app is up.
  static int? _pendingHabitRoute;

  /// Register listeners with awesome_notifications. Call once after initialize().
  static Future<void> registerListeners() async {
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
    );
  }

  /// Handle a notification action. MUST be a static top-level/class method with
  /// the entry-point pragma so it survives AOT for background-isolate dispatch.
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction action) async {
    // When the app is terminated, this runs in a background isolate whose Flutter
    // engine has no plugins registered. Without this, SharedPreferences (used by
    // the pending-completion queue) throws MissingPluginException and the
    // "Complete" press is silently lost.
    DartPluginRegistrant.ensureInitialized();

    final payload = action.payload ?? const {};
    debugPrint(
      '[NOTIF_ACTION] received button="${action.buttonKeyPressed}" '
      'payload=$payload drainPending=${drainPending != null}',
    );

    // other type of notif, just ignore inputs
    if (payload[_payloadTypeKey] != _payloadTypeHabit) return;

    final habitId = int.tryParse(payload[_payloadHabitIdKey] ?? '');
    if (habitId == null) return;

    // complete button action
    if (action.buttonKeyPressed == NotificationService.completeActionKey) {
      final day = _parseDay(payload[_payloadDayKey]);
      if (day == null) {
        // this should never happen in this case but if it ever does
        // it will ignore the complete button input
        debugPrint(
          '[NOTIF_ACTION] missing/invalid habit_day; skipping completion '
          'habit=$habitId',
        );
        return;
      }
      await PendingCompletionQueue.enqueue(habitId, day);
      debugPrint('[NOTIF_ACTION] enqueued completion habit=$habitId day=$day');
      // if user is in the app it will drain immediately
      await drainPending?.call();
      return;
    }

    // if user just tapped it takes them to habit details page
    _navigateToHabit(habitId);
  }

  /// On cold start, route to a habit if the app was launched from a tap.
  static Future<void> handleColdStart() async {
    final action = await AwesomeNotifications().getInitialNotificationAction(
      removeFromActionEvents: true,
    );
    if (action == null) return;
    final payload = action.payload ?? const {};
    if (payload[_payloadTypeKey] != _payloadTypeHabit) return;
    if (action.buttonKeyPressed == NotificationService.completeActionKey) {
      return; // completion handled via the queue, not navigation
    }
    final habitId = int.tryParse(payload[_payloadHabitIdKey] ?? '');
    if (habitId != null) _navigateToHabit(habitId);
  }

  static void _navigateToHabit(int habitId) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingHabitRoute = habitId;
      return;
    }
    nav.push(
      MaterialPageRoute(builder: (_) => HabitDetailsPage(habitId: habitId)),
    );
  }

  /// Called once the app UI is ready to flush any route captured before the
  /// navigator existed.
  static void consumePendingRoute() {
    final habitId = _pendingHabitRoute;
    if (habitId == null) return;
    _pendingHabitRoute = null;
    _navigateToHabit(habitId);
  }

  static DateTime? _parseDay(String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
