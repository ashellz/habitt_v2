import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/timer_provider.dart';
import 'package:habitt/util/hold_complete_tip.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/checkmark.dart';
import 'package:habitt/widgets/default/confetti_burst.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:habitt/widgets/dialogs/timer_dialog.dart';
import 'package:provider/provider.dart';

class NewHabitProgress extends StatefulWidget {
  const NewHabitProgress({
    super.key,
    required this.habit,
    this.color,
    this.extraTapArea = true,
    this.secondaryCheckmarks = false,
    this.isDemo = false,
  });

  final Habit habit;
  final Color? color;
  final bool extraTapArea;
  final bool secondaryCheckmarks;
  final bool isDemo;

  @override
  State<NewHabitProgress> createState() => _NewHabitProgressState();
}

// how far past target + tolerance the pie stays empty for timeOfDay habits
const int _timeOfDayProgressWindowMinutes = 240;

class _NewHabitProgressState extends State<NewHabitProgress> {
  double getProgressValue({int? liveDurationSeconds}) {
    final habit = widget.habit;

    if (habit.completed || habit.skipped) return 1.0;

    // timeOfDay (bedtime/wake time): earlier is better, values are minutes of
    // day. Nothing logged = no progress; otherwise the pie fills as the logged
    // time gets closer to target + tolerance (completed is handled above).
    if (habit.tracksTimeOfDay) {
      if (habit.amountCompleted <= 0) return 0.0;
      final lateness =
          habit.amountCompleted - (habit.amount + habit.toleranceMinutes);
      if (lateness <= 0) return 1.0;
      return (1 - lateness / _timeOfDayProgressWindowMinutes).clamp(0.0, 1.0);
    }

    if (habit.tracksAmount) {
      if (habit.amount <= 0) return 0.0; // avoiding division by zero
      final progress = habit.amountCompleted / habit.amount;
      return progress.clamp(0.0, 1.0);
    }

    if (habit.tracksDuration) {
      // use timer progress if available, otherwise use the habits completed duration
      if (habit.duration <= 0) return 0.0; // avoiding division by zero
      final completed = liveDurationSeconds ?? habit.durationCompleted;
      final progress = completed / habit.duration;
      return progress.clamp(0.0, 1.0);
    }

    return 0.0;
  }

  double _scale = 1.0;

  final _checkmarkKey = GlobalKey();
  late bool _lastCompleted;
  // set when the user taps/holds to complete, so completions from elsewhere
  // (Health sync, notification actions) don't pop confetti
  bool _confettiArmed = false;

  @override
  void initState() {
    super.initState();
    _lastCompleted = widget.habit.completed;
  }

  void _burstConfetti() {
    final box = _checkmarkKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final cp = context.read<ColorProvider>();
    ConfettiBurst.show(
      context,
      origin: box.localToGlobal(box.size.center(Offset.zero)),
      colors: [
        widget.color ?? cp.main,
        cp.orange300,
        cp.mid,
        const Color(0xFF4FC3F7),
        const Color(0xFFF06292),
      ],
    );
  }

  void _trackCompletion() {
    final completed = widget.habit.completed;
    if (completed == _lastCompleted) return;
    _lastCompleted = completed;
    if (completed && _confettiArmed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _burstConfetti();
      });
    }
    _confettiArmed = false;
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    _trackCompletion();
    final stateProvider = context.read<StateProvider>();

    // rebuild progress every second
    final liveDurationSeconds = context.select<TimerProvider, int?>(
      (t) => t.liveProgressFor(widget.habit.id),
    );

    final progress = getProgressValue(liveDurationSeconds: liveDurationSeconds);
    final cp = context.watch<ColorProvider>();

    // the timer provider marks the habit completed itself once the target is
    // reached, so habit.completed is all this needs to look at
    final showPie = progress > 0 && progress < 1;

    return GestureDetector(
      onTap:
          widget.isDemo
              ? null
              : () {
                setState(() {
                  _scale = 0.9;
                });
                Future.delayed(const Duration(milliseconds: 150), () {
                  setState(() {
                    _scale = 1.0;
                  });
                });

                if (!widget.habit.hasTrackingType) {
                  _confettiArmed = !widget.habit.completed;
                  habitProvider.completeHabit(
                    widget.habit.id,
                    context,
                    stateProvider,
                  );
                } else {
                  final selected = habitProvider.selectedDate;
                  final now = DateTime.now();
                  final isToday =
                      selected == null ||
                      (selected.year == now.year &&
                          selected.month == now.month &&
                          selected.day == now.day);
                  final wasCompleted = widget.habit.completed;
                  showDialogSheet(
                    context: context,
                    builder: (context) {
                      if (widget.habit.tracksAmount) {
                        return LogProgressDialog(
                          progressType: ProgressType.amount,
                          habit: widget.habit,
                        );
                      } else if (widget.habit.tracksTimeOfDay) {
                        return LogProgressDialog(
                          progressType: ProgressType.timeOfDay,
                          habit: widget.habit,
                        );
                      } else if (isToday && widget.habit.supportsTimer) {
                        return TimerDialog(habit: widget.habit);
                      } else {
                        return LogProgressDialog(
                          progressType: ProgressType.duration,
                          habit: widget.habit,
                        );
                      }
                    },
                  ).then((_) {
                    if (!mounted) return;
                    // completed inside the dialog: pop once it's out of the way
                    if (!wasCompleted && widget.habit.completed) {
                      _burstConfetti();
                    }
                    if (mounted) HoldCompleteTip.showIfNeeded(context);
                  });
                }
              },
      onTapDown:
          widget.isDemo
              ? null
              : (context) {
                HapticFeedback.selectionClick();
                setState(() {
                  _scale = 0.9;
                });
              },
      onTapCancel:
          widget.isDemo
              ? null
              : () {
                setState(() {
                  _scale = 1.0;
                });
              },
      onTapUp:
          widget.isDemo
              ? null
              : (context) {
                HapticFeedback.selectionClick();
                setState(() {
                  _scale = 1.0;
                });
              },
      onLongPress:
          widget.isDemo
              ? null
              : () {
                _confettiArmed = !widget.habit.completed;
                habitProvider.completeHabit(
                  widget.habit.id,
                  context,
                  stateProvider,
                );
              },
      child: Container(
        color: Colors.transparent,
        width: 24 + (widget.extraTapArea ? 32 : 0),
        height: 42,
        child: Center(
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              key: _checkmarkKey,
              width: 24,
              height: 24,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey(showPie),
                  child:
                      showPie
                          ? TweenAnimationBuilder<double>(
                            key: const ValueKey('partial-progress'),
                            tween: Tween<double>(end: progress),
                            duration: const Duration(milliseconds: 1250),
                            curve: Curves.easeInOut,
                            builder: (context, animatedProgress, child) {
                              return _CircularProgressPie(
                                progress: animatedProgress,
                                color: widget.color ?? cp.main,
                              );
                            },
                          )
                          : Checkmark(
                            value: widget.habit.completed,
                            secondaryCheckmarks: widget.secondaryCheckmarks,
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

class _CircularProgressPie extends StatelessWidget {
  const _CircularProgressPie({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _CircularProgressPiePainter(
          progress: progress.clamp(0.0, 1.0),
          color: color,
        ),
      ),
    );
  }
}

class _CircularProgressPiePainter extends CustomPainter {
  const _CircularProgressPiePainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.transparent;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..color = color;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      true,
      progressPaint,
    );

    final borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.2);

    canvas.drawCircle(center, radius - 1, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPiePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
