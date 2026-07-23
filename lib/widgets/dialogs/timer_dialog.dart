import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/timer_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/timer_controls/timer_play_pause_button.dart';
import 'package:habitt/widgets/timer_controls/timer_stop_button.dart';
import 'package:habitt/widgets/default/timer_progress.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

class TimerDialog extends StatelessWidget {
  const TimerDialog({super.key, required this.habit});

  final Habit habit;

  static String formatClock(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final tp = context.watch<ThemeProvider>();
    final timer = context.watch<TimerProvider>();
    final loc = AppLocalizations.of(context)!;

    final isActive = timer.isActiveHabit(habit.id);
    final isRunning = isActive && timer.isRunning;
    final isPaused = isActive && timer.isPaused;

    final progressSeconds =
        timer.liveProgressFor(habit.id) ?? habit.durationCompleted;
    final target = habit.duration;
    final isComplete = target > 0 && progressSeconds >= target;

    return NewDefaultDialog(
      title: loc.timerDialogTitle,
      showCloseButton: true,
      overrideDefaultButtons: true,
      tip: loc.timerCloseHint,
      child: Column(
        children: [
          Column(
            spacing: 24,
            children: [
              _timerCircle(cp, tp, progressSeconds, target),
              _timerControls(
                context: context,
                cp: cp,
                progressSeconds: progressSeconds,
                target: target,
                isRunning: isRunning,
                isPaused: isPaused,
                isActive: isActive,
              ),
              Column(
                spacing: 12,
                children: [
                  if (!isComplete)
                    NewDefaultButton(
                      width: double.infinity,
                      label: loc.completeHabit,
                      prefix: Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cp.bg.withValues(alpha: 0.4),
                        ),
                        child: SvgPicture.asset(
                          "assets/images/new-svg/check.svg",
                          colorFilter: ColorFilter.mode(cp.bg, BlendMode.srcIn),
                        ),
                      ),
                      onPressed: () => _completeHabit(context, target),
                    ),
                  NewDefaultButton.secondary(
                    width: double.infinity,
                    label: loc.logProgress,
                    prefix: Container(
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cp.text.withValues(alpha: 0.4),
                      ),
                      child: SvgPicture.asset(
                        "assets/images/new-svg/clock.svg",
                        colorFilter: ColorFilter.mode(cp.bg, BlendMode.srcIn),
                      ),
                    ),
                    onPressed: () => _onLogProgress(context, isRunning),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onPlayPause(BuildContext context) async {
    final timer = context.read<TimerProvider>();
    final habitProvider = context.read<HabitProvider>();

    if (timer.isActiveHabit(habit.id)) {
      if (timer.isRunning) {
        await timer.pause();
      } else {
        timer.resume();
      }
      return;
    }

    // another session running, show decission dialog to switch or cancel
    if (timer.hasActiveTimer) {
      final switchIt = await _confirmSwitch(context);
      if (switchIt != true) return;
      await timer.stop();
    }

    final day = habitProvider.selectedDate ?? DateTime.now();
    timer.start(
      habitId: habit.id,
      day: day,
      durationCompleted: habit.durationCompleted,
    );
  }

  Future<void> _onStop(BuildContext context) async {
    await context.read<TimerProvider>().stop();
  }

  Future<void> _completeHabit(BuildContext context, int target) async {
    final timer = context.read<TimerProvider>();
    final habitProvider = context.read<HabitProvider>();
    if (timer.isActiveHabit(habit.id)) {
      await timer.completeToTarget(target);
    } else {
      habitProvider.completeHabit(
        habit.id,
        context,
        context.read<StateProvider>(),
      );
    }
  }

  Future<void> _onLogProgress(BuildContext context, bool isRunning) async {
    if (isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.timerPauseToEditHint),
        ),
      );
      return;
    }

    final timer = context.read<TimerProvider>();
    Navigator.pop(context);
    await showDialogSheet(
      context: context,
      builder:
          (context) => LogProgressDialog(
            progressType: ProgressType.duration,
            habit: habit,
          ),
    );

    if (timer.isActiveHabit(habit.id)) {
      timer.rebaseline(habit.durationCompleted);
    }
  }

  Future<bool?> _confirmSwitch(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return showDialogSheet<bool>(
      context: context,
      builder:
          (context) => NewDefaultDialog(
            title: loc.timerAlreadyRunningTitle,
            desc: loc.timerSwitchDesc(habit.name),
            primaryButtonLabel: loc.timerStopAndStart,
            secondaryButtonLabel: loc.cancel,
            onPrimaryButtonPressed: () => Navigator.pop(context, true),
            onSecondaryButtonPressed: () => Navigator.pop(context, false),
          ),
    );
  }

  Widget _timerControls({
    required BuildContext context,
    required ColorProvider cp,
    required int progressSeconds,
    required int target,
    required bool isRunning,
    required bool isPaused,
    required bool isActive,
  }) {
    final loc = AppLocalizations.of(context)!;
    final statusText =
        isRunning
            ? loc.timerInProgress
            : isPaused
            ? loc.timerPaused
            : "";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isRunning || isPaused)
                  Container(
                    height: 10,
                    width: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRunning ? cp.error : cp.greyText,
                    ),
                  ),
                Text(
                  formatClock(progressSeconds),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: cp.text,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    "/${formatClock(target)}",
                    style: TextStyle(
                      fontSize: 14,
                      color: cp.isDark ? cp.lightGreyText : cp.greyText,
                    ),
                  ),
                ),
              ],
            ),
            if (statusText.isNotEmpty)
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  color: cp.isDark ? cp.lightGreyText : cp.greyText,
                ),
              ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            TimerPlayPauseButton(
              isRunning: isRunning,
              onTap: () => _onPlayPause(context),
              size: 52,
              outerPadding: 6,
              innerPadding: 10,
              iconSize: 24,
            ),
            TimerStopButton(
              onTap: isActive ? () => _onStop(context) : null,
              enabled: isActive,
              size: 52,
              iconSize: 24,
            ),
          ],
        ),
      ],
    );
  }

  Widget _timerCircle(
    ColorProvider cp,
    ThemeProvider tp,
    int progressSeconds,
    int target,
  ) {
    final progress = target > 0 ? progressSeconds / target : 0.0;
    return Center(
      child: SizedBox(
        height: 240,
        width: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 240,
              width: 240,
              child: TimerRingIndicator(
                progress: progress,
                color: cp.main,
                trackColor: cp.main.withValues(alpha: 0.12),
                lapSeconds: target.toDouble(),
                isDark: cp.isDark,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  TextIcon(habit.iconPath, size: 32),
                  Text(
                    habit.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: cp.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
