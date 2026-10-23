import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/habit_details_page.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/services/habit_route_tracker.dart';
import 'package:habitt/services/main_tab_controller.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/services/pending_completion_queue.dart';
import 'package:habitt/services/unsaved_changes_guard.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
class NotificationActionHandler {
  NotificationActionHandler._();

  static const String _payloadHabitIdKey = 'habit_id';
  static const String _payloadTypeKey = 'notification_type';
  static const String _payloadTypeHabit = 'habit';
  static const String _payloadTypeTimerComplete = 'timer_complete';
  static const String _payloadDayKey = 'habit_day';

  static bool _isHandledType(String? type) =>
      type == _payloadTypeHabit || type == _payloadTypeTimerComplete;

  /// Global navigator key so notifications can route without a widget context.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Set by the app (main isolate) to drain the pending-completion queue.
  /// Null in the background isolate, where we only enqueue.
  static Future<void> Function()? drainPending;

  /// Habit id captured before the navigator was ready (cold start). Consumed by
  /// [consumePendingRoute] once the app is up.
  static int? _pendingHabitRoute;

  /// Notification day paired with [_pendingHabitRoute], so cold-start replay
  /// still applies the correct `selectedDate`.
  static DateTime? _pendingHabitDay;

  /// True while the log-progress dialog opened by a tap is on screen, so a
  /// second tap can't stack another one on top.
  static bool _logDialogOpen = false;

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
    if (!_isHandledType(payload[_payloadTypeKey])) return;

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
    // with the correct day when the notification was fired on
    final day = _parseDay(payload[_payloadDayKey]);
    _navigateToHabit(habitId, day);
  }

  /// On cold start, route to a habit if the app was launched from a tap.
  static Future<void> handleColdStart() async {
    final action = await AwesomeNotifications().getInitialNotificationAction(
      removeFromActionEvents: true,
    );
    if (action == null) return;
    final payload = action.payload ?? const {};
    if (!_isHandledType(payload[_payloadTypeKey])) return;
    if (action.buttonKeyPressed == NotificationService.completeActionKey) {
      return; // completion handled via the queue, not navigation
    }
    final habitId = int.tryParse(payload[_payloadHabitIdKey] ?? '');
    if (habitId != null) {
      final day = _parseDay(payload[_payloadDayKey]);
      _navigateToHabit(habitId, day);
    }
  }

  /// Resolves a notification tap.
  ///
  /// Amount and duration habits that can be logged by hand open the
  /// log-progress dialog over the main page (an open habit details page is
  /// closed first), with no navigation to details. Anything
  /// else (checkbox habits, Health-linked habits, habits already done or
  /// skipped) opens the habit's details page, see [_openDetails].
  static void _navigateToHabit(int habitId, DateTime? day) {
    if (UnsavedChangesGuard.isBlocking) {
      return;
    }

    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingHabitRoute = habitId;
      _pendingHabitDay = day;
      return;
    }

    unawaited(_handleTap(nav, habitId, day));
  }

  static Future<void> _handleTap(
    NavigatorState nav,
    int habitId,
    DateTime? day,
  ) async {
    // a dialog from an earlier tap is still up; a second one would stack on
    // top of it and, with another day selected, log into the wrong day
    if (_logDialogOpen) return;

    final habitProvider = nav.context.read<HabitProvider>();
    // cold start: habits may still be loading when the tap is replayed
    await _waitUntilInitialized(habitProvider);

    // `selectedDate` decides which day the dialog (and the details page)
    // writes to, so it has to follow the notification's day
    if (day != null) habitProvider.setSelectedDate(day);

    final habit = _habitForDay(habitProvider, habitId, day);
    final progressType = habit == null ? null : _logProgressTypeFor(habit);
    // the navigator may have changed while waiting on a cold start
    final liveNav = navigatorKey.currentState;
    if (liveNav == null) return;
    final overlayContext = liveNav.overlay?.context;
    if (habit == null || progressType == null || overlayContext == null) {
      _openDetails(liveNav, habitId);
      return;
    }

    if (!overlayContext.mounted) return;

    // a habit details page is open: close it so the dialog sits on the main
    // page instead of on top of whatever habit the user was looking at
    if (HabitRouteTracker.currentTopHabitId != null) {
      liveNav.pop();
    }

    _logDialogOpen = true;
    unawaited(
      showDialogSheet(
        context: overlayContext,
        builder:
            (_) => LogProgressDialog(progressType: progressType, habit: habit),
      ).whenComplete(() => _logDialogOpen = false),
    );
  }

  static Future<void> _waitUntilInitialized(HabitProvider habitProvider) async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (!habitProvider.isInitialized && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// The dialog to log progress with, or null when the habit should open its
  /// details page instead. Health-linked habits are excluded because their
  /// progress comes from Health and a hand edit would pause that sync.
  static ProgressType? _logProgressTypeFor(Habit habit) {
    if (habit.healthMetric != null || habit.completed || habit.skipped) {
      return null;
    }
    if (habit.tracksAmount) return ProgressType.amount;
    if (habit.tracksDuration) return ProgressType.duration;
    return null;
  }

  /// Opens a fixed target stack (MainPage -> HabitDetails(habitId)) by
  /// reconciling against whatever is currently on screen, rather than
  /// unconditionally stacking a new page:
  ///  - that habit's details page is already showing -> no-op
  ///  - a different habit's details page is showing -> replace it
  ///  - anything else -> pop back to the root (MainPage) and push
  static void _openDetails(NavigatorState nav, int habitId) {
    final currentTopHabitId = HabitRouteTracker.currentTopHabitId;
    if (currentTopHabitId == habitId) {
      return;
    }

    if (currentTopHabitId != null) {
      nav.pop();
    } else {
      MainTabController.resetToMainTab();
      nav.popUntil((route) => route.isFirst);
    }

    nav.push(_habitDetailsRoute(habitId));
  }

  static Route<void> _habitDetailsRoute(int habitId) {
    return MaterialPageRoute(
      settings: RouteSettings(arguments: habitId),
      builder: (_) => HabitDetailsPage(habitId: habitId),
    );
  }

  /// Called once the app UI is ready to flush any route captured before the
  /// navigator existed (cold start). Routes back through [_navigateToHabit]
  /// so the cold-start tap gets the same handling as any other tap.
  static void consumePendingRoute() {
    final habitId = _pendingHabitRoute;
    if (habitId == null) return;
    final day = _pendingHabitDay;
    _pendingHabitRoute = null;
    _pendingHabitDay = null;
    _navigateToHabit(habitId, day);
  }

  static Habit? _habitForDay(
    HabitProvider habitProvider,
    int habitId,
    DateTime? day,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final source =
        day == null || day == today
            ? habitProvider.habits
            : habitProvider.getHabitsFromDay(day, hydrateMissing: true);
    for (final habit in source) {
      if (habit.id == habitId) return habit;
    }
    return null;
  }

  static DateTime? _parseDay(String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
