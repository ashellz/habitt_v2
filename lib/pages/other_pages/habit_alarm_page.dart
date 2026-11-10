import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/alarm_ring_service.dart';
import 'package:habitt/services/alarm_screen_service.dart';
import 'package:habitt/services/notification_action_handler.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/habit_alarm/alarm_clock.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';

/// A ringing habit alarm, as delivered by its notification.
class HabitAlarm {
  const HabitAlarm({
    required this.notificationId,
    required this.habitId,
    required this.day,
    required this.title,
    required this.body,
  });

  final int notificationId;
  final int habitId;

  /// Day the reminder was for, used when completing from the alarm.
  final DateTime? day;
  final String title;
  final String body;
}

/// Full-screen ringing alarm (Android), opened by the alarm notification's
/// full-screen intent or by tapping it. The sound belongs to the notification,
/// so it rings until this page dismisses that notification.
/// See docs/habit_alarms.md.
class HabitAlarmPage extends StatefulWidget {
  const HabitAlarmPage({super.key, required this.alarm});

  final HabitAlarm alarm;

  @override
  State<HabitAlarmPage> createState() => _HabitAlarmPageState();
}

class _HabitAlarmPageState extends State<HabitAlarmPage> {
  late final Habit? _habit = _findHabit(widget.alarm.habitId);
  bool _closing = false;

  static Habit? _findHabit(int habitId) {
    for (final habit in Hive.box<Habit>('habits').values) {
      if (habit.id == habitId) return habit;
    }
    return null;
  }

  /// Same rule as the notification's "Complete" button: Health-linked habits
  /// get their progress from Health, so they can only be dismissed.
  bool get _canComplete =>
      widget.alarm.day != null && _habit != null && _habit.healthMetric == null;

  @override
  void dispose() {
    // the rest of the app must never show over the lock screen
    AlarmScreenService.setShowOverLockScreen(false);
    super.dispose();
  }

  Future<void> _close({required bool complete}) async {
    if (_closing) return;
    _closing = true;
    // stops the ringing (Android's native sound also stops by itself once the
    // notification is gone, this just makes it immediate)
    await AwesomeNotifications().dismiss(widget.alarm.notificationId);
    await AlarmRingService.stopRinging();
    if (complete)
      await NotificationActionHandler.completeFromAlarm(widget.alarm);
    await AlarmScreenService.setShowOverLockScreen(false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final title =
        widget.alarm.title.isNotEmpty
            ? widget.alarm.title
            : (_habit?.name ?? loc.habitAlarmTitle);

    return DefaultAnnotatedRegion(
      // the alarm only ends with one of the buttons, like a clock app
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: cp.bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                children: [
                  // ─── Clock ────────────────────────────────────────────
                  const Spacer(flex: 3),
                  const AlarmClock(),
                  const SizedBox(height: 56),

                  // ─── Habit ────────────────────────────────────────────
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(flex: 2),

                  // ─── Actions ──────────────────────────────────────────
                  Row(
                    spacing: 8,
                    children: [
                      if (_canComplete)
                        _actionButton(
                          label: loc.notificationCompleteAction,
                          color: cp.main,
                          textColor: cp.bg,
                          onTap: () => _close(complete: true),
                        ),
                      _actionButton(
                        label: loc.notificationDismissAction,
                        color: cp.secondaryButton,
                        textColor: cp.text,
                        onTap: () => _close(complete: false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 96,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
