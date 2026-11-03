import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/alarm_screen_service.dart';
import 'package:habitt/services/notification_action_handler.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/habit_alarm/alarm_clock.dart';
import 'package:habitt/widgets/habit_alarm/alarm_pulse_icon.dart';
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
    // stops the ringing
    await AwesomeNotifications().dismiss(widget.alarm.notificationId);
    if (complete) await NotificationActionHandler.completeFromAlarm(widget.alarm);
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
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  // ─── Clock ────────────────────────────────────────────
                  _alarmLabel(cp, loc),
                  const SizedBox(height: 12),
                  const AlarmClock(),

                  // ─── Habit ────────────────────────────────────────────
                  const Spacer(),
                  AlarmPulseIcon(emoji: _habit?.iconPath ?? '⏰'),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.alarm.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.alarm.body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cp.greyText,
                        fontSize: 17,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const Spacer(),

                  // ─── Actions ──────────────────────────────────────────
                  if (_canComplete) ...[
                    NewDefaultButton.primary(
                      height: 60,
                      label: loc.notificationCompleteAction,
                      onPressed: () => _close(complete: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  NewDefaultButton.secondary(
                    height: 60,
                    label: loc.notificationDismissAction,
                    onPressed: () => _close(complete: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _alarmLabel(ColorProvider cp, AppLocalizations loc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Icon(Icons.alarm_rounded, color: cp.main, size: 20),
        Text(
          loc.habitAlarmTitle,
          style: TextStyle(
            color: cp.main,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
