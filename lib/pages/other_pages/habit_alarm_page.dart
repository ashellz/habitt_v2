import 'dart:math' as math;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/alarm_screen_service.dart';
import 'package:habitt/services/notification_action_handler.dart';
import 'package:habitt/widgets/habit_alarm/alarm_clock.dart';
import 'package:habitt/widgets/habit_alarm/alarm_palette.dart';
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
  void initState() {
    super.initState();
    // automatic sheets and the sync pill wait / hide while this is up
    AlarmScreenService.markOpened();
  }

  @override
  void dispose() {
    AlarmScreenService.markClosed();
    // the rest of the app must never show over the lock screen
    AlarmScreenService.setShowOverLockScreen(false);
    super.dispose();
  }

  Future<void> _close({required bool complete}) async {
    if (_closing) return;
    _closing = true;
    // stops the ringing
    await AwesomeNotifications().dismiss(widget.alarm.notificationId);
    if (complete)
      await NotificationActionHandler.completeFromAlarm(widget.alarm);
    await AlarmScreenService.setShowOverLockScreen(false);
    if (mounted) Navigator.of(context).pop();
  }

  // Layout measured from the Pixel Clock ringing screen (393 x 851dp): digits
  // centred at 43.7% of the height, the title's box 123dp below that, 91dp
  // pills 22.5dp from the sides with a 3dp gap, their bottom 13.3% of the
  // height above the screen's bottom.
  static const double _clockCenterFraction = 0.437;
  static const double _titleTopFromClockCenter = 123;
  static const double _buttonsBottomFraction = 0.133;
  static const double _buttonHeight = 91;
  static const double _sideMargin = 22.5;
  static const double _buttonGap = 3;

  static TextStyle _textStyle({
    required Color color,
    required double size,
    required double weight,
    double letterSpacing = 0,
    List<Shadow>? shadows,
  }) => TextStyle(
    fontFamily: 'GoogleSansFlex',
    fontSize: size,
    letterSpacing: letterSpacing,
    color: color,
    shadows: shadows,
    fontVariations: [
      FontVariation('wght', weight),
      const FontVariation('opsz', 24),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final palette = AlarmPalette.fromAccent(cp.theme.accent(isDark: true).main);
    final title =
        widget.alarm.title.isNotEmpty
            ? widget.alarm.title
            : (_habit?.name ?? loc.habitAlarmTitle);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // always dark, like a clock app's ringing screen
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // iOS
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      // the alarm only ends with one of the buttons, like a clock app
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: palette.background,
          body: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final clockCenter = height * _clockCenterFraction;
                final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
                final buttonsBottom = math.max(
                  height * _buttonsBottomFraction,
                  bottomInset + 16,
                );

                return Stack(
                  children: [
                    // ─── Clock ──────────────────────────────────────────
                    Positioned(
                      top: clockCenter - AlarmClock.inkCenterFromTop,
                      left: _sideMargin,
                      right: _sideMargin,
                      child: Center(child: AlarmClock(color: palette.text)),
                    ),

                    // ─── Habit ──────────────────────────────────────────
                    Positioned(
                      top: clockCenter + _titleTopFromClockCenter,
                      left: _sideMargin + 8,
                      right: _sideMargin + 8,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _textStyle(
                          color: palette.text,
                          size: 29.6,
                          weight: 400,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─── Actions ────────────────────────────────────────
                    Positioned(
                      left: _sideMargin,
                      right: _sideMargin,
                      bottom: buttonsBottom,
                      child: Row(
                        spacing: _buttonGap,
                        children: [
                          if (_canComplete)
                            _actionButton(
                              label: loc.notificationCompleteAction,
                              color: palette.primaryButton,
                              textColor: palette.onPrimaryButton,
                              onTap: () => _close(complete: true),
                            ),
                          _actionButton(
                            label: loc.notificationDismissAction,
                            color: palette.secondaryButton,
                            textColor: palette.onSecondaryButton,
                            onTap: () => _close(complete: false),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
            height: _buttonHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textStyle(
                    color: textColor,
                    size: 22.5,
                    weight: 500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
