import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/habit_widget/completion_dialog.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/amount_display.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/duration_display.dart';
import 'package:provider/provider.dart';

class CompletionDisplay extends StatefulWidget {
  const CompletionDisplay({
    super.key,
    required this.colorProvider,
    required this.editable,
    required this.habit,
  });

  final ColorProvider colorProvider;
  final bool editable;
  final Habit habit;

  @override
  State<CompletionDisplay> createState() => _CompletionDisplayState();
}

class _CompletionDisplayState extends State<CompletionDisplay> {
  double getProgressValue() {
    final habit = widget.habit;

    if (habit.amount == 0 && habit.duration == 0) {
      // Basic habit (no amount/duration), just check if completed or skipped
      if (habit.completed || habit.skipped) return 1.0;
      return 0.0;
    }

    if (habit.amount > 0) {
      // Habit tracked by amount
      if (habit.amount == 0) return 0.0; // Avoid divide by zero
      final progress = habit.amountCompleted / habit.amount;
      return progress.clamp(0.0, 1.0);
    }

    if (habit.duration > 0) {
      // Habit tracked by duration
      if (habit.duration == 0) return 0.0; // Avoid divide by zero
      final progress = habit.durationCompleted / habit.duration;
      return progress.clamp(0.0, 1.0);
    }

    return 0.0;
  }

  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.read<HabitProvider>();

    // Main widget
    return GestureDetector(
      onTap:
          widget.editable
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

                // If no amount or duration, toggle completion
                if (widget.habit.amount == 0 && widget.habit.duration == 0 ||
                    widget.habit.completed ||
                    widget.habit.skipped) {
                  habitProvider.completeHabit(widget.habit.id);
                } else {
                  // Opens a dialog for selecting amount/duration completion
                  showCupertinoDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (context) => CompletionDialog(habit: widget.habit),
                  );
                }
              },
      onTapDown: (context) {
        if (widget.editable) return;
        setState(() {
          _scale = 0.9;
        });
      },
      onTapCancel: () {
        if (widget.editable) return;
        setState(() {
          _scale = 1.0;
        });
      },
      onTapUp: (context) {
        if (widget.editable) return;
        setState(() {
          _scale = 1.0;
        });
      },
      onLongPress: () {
        if (widget.editable) return;
        habitProvider.completeHabit(widget.habit.id);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _scale,
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: 50,
          width: 50,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          child: Stack(
            children: [
              Positioned.fill(
                child: RotatedBox(
                  quarterTurns: -1,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(begin: 0, end: getProgressValue()),
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        color:
                            widget.habit.skipped
                                ? widget.colorProvider.standardColor
                                : widget
                                    .colorProvider
                                    .colorScheme
                                    .darkerStandardColor,
                        backgroundColor:
                            widget.colorProvider.colorScheme.strokeColor,
                      );
                    },
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(4.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder:
                      (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                  child: KeyedSubtree(
                    key: ValueKey<bool>(widget.habit.completed),
                    child: getCompletionWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Center icon
  Widget centerIcon() {
    return Center(
      child: Icon(
        widget.habit.completed || widget.habit.skipped
            ? Icons.check
            : Icons.close,
        color: Color(0xFFF8F9FA),
      ),
    );
  }

  // Middle child inside of the container (checkmark or amount/duration)
  Widget getCompletionWidget() {
    if (widget.habit.amount > 0 &&
        !widget.habit.completed &&
        !widget.habit.skipped) {
      return AmountDisplay(
        habit: widget.habit,
        colorProvider: widget.colorProvider,
      );
    } else if (widget.habit.duration > 0 &&
        !widget.habit.completed &&
        !widget.habit.skipped) {
      return DurationDisplay(habit: widget.habit);
    } else {
      return centerIcon();
    }
  }
}
