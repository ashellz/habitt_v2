import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/default/glass_blur_container.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/duration_completion_dialog.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/enter_amount_slider_dialog.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/amount_display.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/duration_display.dart';
import 'package:provider/provider.dart';

class CompletionDisplay extends StatefulWidget {
  const CompletionDisplay({
    super.key,
    required this.tp,
    required this.editable,
    required this.habit,
    required this.isToday,
  });

  final ThemeProvider tp;
  final bool editable;
  final Habit habit;
  final bool isToday;

  @override
  State<CompletionDisplay> createState() => _CompletionDisplayState();
}

class _CompletionDisplayState extends State<CompletionDisplay> {
  double getProgressValue() {
    final habit = widget.habit;

    if (habit.completed || habit.skipped) return 1.0;

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

  /*
  widget.habit.skipped
                                ? widget.tp.borderColor.darken(
                                  widget.tp.isDark ? 0 : 45,
                                )
                                : widget.habit.getColor ??
                                    widget.tp.successColor,
   */

  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.read<HabitProvider>();
    final tp = context.read<ThemeProvider>();
    final focusedDay = context.watch<CalendarProvider>().focusedDay;
    final stateProvider = context.read<StateProvider>();

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
                  habitProvider.completeHabit(
                    widget.habit.id,
                    context,
                    stateProvider,
                    day: widget.isToday ? DateTime.now() : focusedDay,
                  );
                } else {
                  // Opens a dialog for selecting amount/duration completion

                  if (widget.habit.amount > 0) {
                    showAmountSliderDialog(
                      context,
                      widget.habit,
                      widget.isToday ? DateTime.now() : focusedDay,
                    );
                  } else {
                    showDurationCompletionDialog(
                      context,
                      widget.habit,
                      widget.isToday ? DateTime.now() : focusedDay,
                    );
                  }
                }
              },
      onTapDown: (context) {
        if (widget.editable) return;
        HapticFeedback.selectionClick();
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
        HapticFeedback.selectionClick();
        setState(() {
          _scale = 1.0;
        });
      },
      onLongPress: () {
        if (widget.editable) return;
        habitProvider.completeHabit(
          widget.habit.id,
          context,
          stateProvider,
          day: widget.isToday ? DateTime.now() : focusedDay,
        );
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _scale,
        child: Container(
          clipBehavior: Clip.hardEdge,
          height: 50,
          width: 50,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
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
                        color: widget.habit.getCompletionColor(
                          tp,
                          context.read<PreferencesProvider>().colorfulness,
                        ),
                        backgroundColor: widget.tp.mutedBgColor,
                      );
                    },
                  ),
                ),
              ),

              GlassBlurContainer(forceBlur: true),

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
    return Center(child: Icon(Icons.check, color: Color(0xFFF8F9FA)));
  }

  // Middle child inside of the container (checkmark or amount/duration)
  Widget getCompletionWidget() {
    if (widget.habit.amount > 0 &&
        !widget.habit.completed &&
        !widget.habit.skipped) {
      return AmountDisplay(habit: widget.habit, tp: widget.tp);
    } else if (widget.habit.duration > 0 &&
        !widget.habit.completed &&
        !widget.habit.skipped) {
      return DurationDisplay(habit: widget.habit);
    } else {
      return centerIcon();
    }
  }
}
