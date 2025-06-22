import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/duration_completion_dialog.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/enter_amount_slider_dialog.dart';
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

                  if (widget.habit.amount > 0) {
                    showAnimatedBlurDialog(context, widget.habit);
                  } else {
                    showCupertinoDialog(
                      barrierDismissible: true,
                      context: context,
                      builder:
                          (context) =>
                              DurationCompletionDialog(habit: widget.habit),
                    );
                  }
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

void showAnimatedBlurDialog(BuildContext context, Habit habit) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Enter Amount',
    transitionDuration: const Duration(
      milliseconds: 150,
    ), // Your animation duration
    // This builder is for the content of the dialog.
    // We pass the simplified dialog widget here.
    pageBuilder: (context, animation, secondaryAnimation) {
      return EnterAmountSliderDialog(habit: habit);
    },

    // This builder is for the transition animation.
    // This is where we will build the BackdropFilter.
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // The `animation` object here is an Animation<double> that goes from 0.0 to 1.0
      // over the course of the `transitionDuration`.

      // Animate the sigma value for the blur
      final double blurValue = animation.value * 4; // Max blur of 8

      // Animate the tint color's opacity
      final double tintOpacity = animation.value * 0.1; // Max opacity of 0.2

      return Stack(
        children: [
          // This BackdropFilter is now part of the transition,
          // so it correctly blurs the screen behind the route.
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
            child: Container(color: Colors.black.withOpacity(tintOpacity)),
          ),

          // Use a FadeTransition to fade in the dialog content itself.
          // The `child` here is the EnterAmountSliderDialog built by pageBuilder.
          FadeTransition(
            opacity: animation, // Use the same animation controller
            child: Center(child: child),
          ),
        ],
      );
    },
  );
}
