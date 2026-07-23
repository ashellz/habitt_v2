import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/timer_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/timer_controls/timer_play_pause_button.dart';
import 'package:habitt/widgets/timer_controls/timer_stop_button.dart';
import 'package:habitt/widgets/default/timer_progress.dart';
import 'package:habitt/widgets/dialogs/timer_dialog.dart';
import 'package:provider/provider.dart';

class TimerPillWidget extends StatelessWidget {
  const TimerPillWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    final cp = context.watch<ColorProvider>();

    if (!timer.hasActiveTimer) return const SizedBox.shrink();

    final habitProvider = context.read<HabitProvider>();
    final id = timer.activeHabitId!;
    Habit? habit;
    for (final h in habitProvider.habits) {
      if (h.id == id) {
        habit = h;
        break;
      }
    }
    if (habit == null) return const SizedBox.shrink();

    final isRunning = timer.isRunning;
    final progressSeconds = timer.liveProgressSeconds;
    final target = habit.duration;
    final progress = target > 0 ? progressSeconds / target : 0.0;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
      child: GestureDetector(
        onTap: () {
          final h = habit!;
          showDialogSheet(
            context: context,
            builder: (_) => TimerDialog(habit: h),
          );
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16.5,
              ),
              decoration: BoxDecoration(
                color: cp.habitBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: cp.border, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 8,
                              width: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isRunning ? cp.error : cp.greyText,
                              ),
                            ),
                            Text(
                              TimerDialog.formatClock(progressSeconds),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: cp.text,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "/${TimerDialog.formatClock(target)}",
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    cp.isDark ? cp.lightGreyText : cp.greyText,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          isRunning
                              ? AppLocalizations.of(context)!.timerInProgress
                              : AppLocalizations.of(context)!.timerPaused,
                          style: TextStyle(
                            fontSize: 13,
                            color: cp.isDark ? cp.lightGreyText : cp.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TimerPlayPauseButton(
                    isRunning: isRunning,
                    onTap: () => isRunning ? timer.pause() : timer.resume(),
                  ),
                  const SizedBox(width: 8),
                  TimerStopButton(onTap: () => timer.stop()),
                ],
              ),
            ),
            // progress indicator
            Positioned.fill(
              child: IgnorePointer(
                child: TimerStadiumIndicator(
                  progress: progress,
                  color: cp.main,
                  trackColor: cp.border,
                  strokeWidth: 2,
                  inset: 2,
                  lapSeconds: target.toDouble(),
                  isDark: cp.isDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
