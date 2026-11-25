import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/services/lighter_day_offers.dart';
import 'package:habitt/services/lighter_day_policy.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:habitt/services/notification_sounds.dart';
import 'package:habitt/services/notification_text/locale_resolver.dart';
import 'package:habitt/util/custom_amount_label.dart';
import 'package:habitt/util/date_key.dart';
import 'package:habitt/util/goal_value_format.dart';

/// The evening goal check-in notification (20:25): one per evening for the
/// highest-priority lighter-day offer. Re-evaluated whenever the goal check-in
/// flow runs (app open, resume, any habit change). See docs/goal_check_in.md.
class GoalCheckInNotifications {
  const GoalCheckInNotifications._();

  static const String payloadType = 'goal_check_in';
  static const String payloadHabitKey = 'habit_id';
  static const String payloadTypeKey = 'notification_type';
  static const String payloadDayKey = 'habit_day';
  static const String payloadGoalKey = 'goal';

  /// Sets today's goal to the logged progress, in the background.
  static const String countItAction = 'GOAL_COUNT_IT';

  /// Opens the app on the lighter-day sheet.
  static const String chooseAction = 'GOAL_CHOOSE';

  static const String keepAction = 'GOAL_KEEP';

  static const int todayId = 1950000000;

  /// The tentative one for tomorrow evening, replaced on the next app open.
  static const int tomorrowId = 1950000001;

  static bool _running = false;

  static Future<void> cancelAll() async {
    await AwesomeNotifications().cancel(todayId);
    await AwesomeNotifications().cancel(tomorrowId);
  }

  /// Schedules or cancels today's and tomorrow's goal check-in.
  static Future<void> refresh(
    HabitProvider hp,
    NotificationsProvider np, {
    DateTime? now,
  }) async {
    if (_running) return;
    _running = true;
    try {
      if (!np.isGoalCheckInEnabled ||
          !await AwesomeNotifications().isNotificationAllowed()) {
        await cancelAll();
        return;
      }
      final current = now ?? DateTime.now();
      final loc = await HabitNotificationLocaleResolver.resolveFromPreferences();
      final singulars = await CustomAmountLabel.loadCustomSingularsFromPrefs();

      // ─── Today ────────────────────────────────────────────
      final evening = LighterDayOffers.eveningOf(current);
      final offer =
          current.isBefore(evening)
              ? LighterDayOffers.best(hp, now: current)
              : null;
      if (offer == null) {
        await AwesomeNotifications().cancel(todayId);
      } else {
        await _schedule(
          id: todayId,
          at: evening,
          offer: offer,
          loc: loc,
          singulars: singulars,
        );
      }

      // ─── Tomorrow (tentative) ─────────────────────────────
      final tomorrow = addCalendarDays(current, 1);
      final next = _tomorrowCandidate(hp, current, tomorrow);
      if (next == null) {
        await AwesomeNotifications().cancel(tomorrowId);
      } else {
        await _schedule(
          id: tomorrowId,
          at: LighterDayOffers.eveningOf(tomorrow),
          offer: next,
          loc: loc,
          singulars: singulars,
        );
      }
    } catch (e) {
      debugPrint('[GOAL_CHECK_IN] notification refresh failed: $e');
    } finally {
      _running = false;
    }
  }

  /// A habit not done today that is due tomorrow: if the app isn't opened, it
  /// has a missed day before tomorrow, so it qualifies with no progress.
  static LighterDayOffer? _tomorrowCandidate(
    HabitProvider hp,
    DateTime now,
    DateTime tomorrow,
  ) {
    for (var i = 0; i < hp.todaysHabits.length; i++) {
      final h = hp.todaysHabits[i];
      if (h.completed || h.skipped || h.optional || h.isPaused == true) {
        continue;
      }
      if (h.isDeleted == true || !hp.appearsOnDay(h, tomorrow)) continue;
      if (h.trackingType != HabitTrackingType.amount &&
          h.trackingType != HabitTrackingType.duration) {
        continue;
      }
      final isDuration = h.trackingType == HabitTrackingType.duration;
      final goal = isDuration ? h.duration : h.amount;
      final values = LighterDayPolicy.offeredValues(
        progress: 0,
        goal: goal,
        isDuration: isDuration,
      );
      if (values.isEmpty) continue;
      return LighterDayOffer(
        habit: h,
        kind: LighterDayKind.lighter,
        values: values,
        progress: 0,
        usualGoal: goal,
        isDuration: isDuration,
        daysLeft: LighterDayPolicy.allowancePerWeek,
        missedYesterday: true,
        order: i,
      );
    }
    return null;
  }

  static Future<void> _schedule({
    required int id,
    required DateTime at,
    required LighterDayOffer offer,
    required AppLocalizations loc,
    required Map<String, String> singulars,
  }) async {
    final habit = offer.habit;
    String fmt(int v) =>
        formatGoalValue(habit, v, loc, customSingulars: singulars);
    final icon = habit.iconPath.trim();
    final rawTitle = loc.goalCheckInNotifTitle(
      habit.name,
      fmt(offer.progress),
      fmt(offer.usualGoal),
    );
    final title = icon.isNotEmpty && !icon.contains('assets')
        ? '$icon $rawTitle'
        : rawTitle;
    final String body;
    if (offer.streakAtRisk != null) {
      body = loc.goalCheckInNotifStreakBody(offer.streakAtRisk!);
    } else if (offer.progress > 0) {
      body = loc.goalCheckInNotifBody(fmt(offer.usualGoal));
    } else {
      body = loc.goalCheckInNotifBodyZero;
    }

    final isSave = offer.kind == LighterDayKind.saveStreak;
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: NotificationSounds.channelForKeyOrDefault(
          NotificationService.globalSoundKey,
        ),
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Reminder,
        payload: {
          payloadHabitKey: habit.id.toString(),
          payloadTypeKey: payloadType,
          payloadDayKey: dateKey(at),
          payloadGoalKey: offer.progress.toString(),
        },
      ),
      actionButtons: [
        if (!isSave && offer.progress > 0)
          NotificationActionButton(
            key: countItAction,
            label: loc.goalCheckInNotifCountIt(fmt(offer.progress)),
            actionType: ActionType.SilentBackgroundAction,
            autoDismissible: true,
          ),
        NotificationActionButton(
          key: chooseAction,
          label: isSave ? loc.saveStreakLog : loc.goalCheckInNotifChoose,
          actionType: ActionType.Default,
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: keepAction,
          label: loc.lighterDayKeep(fmt(offer.usualGoal)),
          actionType: ActionType.DismissAction,
          autoDismissible: true,
        ),
      ],
      schedule: NotificationCalendar.fromDate(date: at, allowWhileIdle: true),
    );
  }
}
