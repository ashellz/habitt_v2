import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/hold_complete_tip.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/checkmark.dart';
import 'package:habitt/widgets/dialogs/log_progress_dialog.dart';
import 'package:provider/provider.dart';

class NewHabitProgress extends StatefulWidget {
  const NewHabitProgress({
    super.key,
    required this.habit,
    this.focusedDay,
    this.color,
    this.extraTapArea = true,
    this.secondaryCheckmarks = false,
    this.isDemo = false,
  });

  final Habit habit;
  final DateTime? focusedDay;
  final Color? color;
  final bool extraTapArea;
  final bool secondaryCheckmarks;
  final bool isDemo;

  @override
  State<NewHabitProgress> createState() => _NewHabitProgressState();
}

class _NewHabitProgressState extends State<NewHabitProgress> {
  double getProgressValue() {
    final habit = widget.habit;

    if (habit.completed || habit.skipped) return 1.0;

    if (habit.tracksAmount) {
      // Habit tracked by amount
      if (habit.amount <= 0) return 0.0; // Avoid divide by zero
      final progress = habit.amountCompleted / habit.amount;
      return progress.clamp(0.0, 1.0);
    }

    if (habit.tracksDuration) {
      // Habit tracked by duration
      if (habit.duration <= 0) return 0.0; // Avoid divide by zero
      final progress = habit.durationCompleted / habit.duration;
      return progress.clamp(0.0, 1.0);
    }

    return 0.0;
  }

  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final stateProvider = context.read<StateProvider>();
    final progress = getProgressValue();
    final cp = context.watch<ColorProvider>();

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
                  habitProvider.completeHabit(
                    widget.habit.id,
                    context,
                    stateProvider,
                  );
                } else {
                  showDialogSheet(
                    context: context,
                    builder: (context) {
                      return LogProgressDialog(
                        progressType:
                            widget.habit.tracksAmount
                                ? ProgressType.amount
                                : ProgressType.duration,
                        habit: widget.habit,
                      );
                    },
                  ).then((_) {
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
              width: 24,
              height: 24,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: KeyedSubtree(
                  key: ValueKey(progress > 0 && progress < 1),
                  child:
                      progress > 0 && progress < 1
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
