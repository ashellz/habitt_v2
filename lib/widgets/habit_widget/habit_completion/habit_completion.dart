import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/default/glass_blur_container.dart';
import 'package:habitt/widgets/habit_details/select_habit_color_sheet.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/old/duration_completion_dialog.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/old/enter_amount_slider_dialog.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/amount_display.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/duration_display.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

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
  bool _hasAnimatedProgress = false;
  double _lastProgress = 0.0;

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
              ? () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder:
                    (context) => SelectHabitColorSheet(
                      tp: tp,
                      fromCompletionWidget: true,
                    ),
              )
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
                if (!widget.habit.hasTrackingType ||
                    widget.habit.completed ||
                    widget.habit.skipped) {
                  habitProvider.completeHabit(
                    widget.habit.id,
                    context,
                    stateProvider,
                  );
                } else {
                  // Opens a dialog for selecting amount/duration completion

                  if (widget.habit.tracksAmount) {
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
        HapticFeedback.selectionClick();
        setState(() {
          _scale = 0.9;
        });
      },
      onTapCancel: () {
        setState(() {
          _scale = 1.0;
        });
      },
      onTapUp: (context) {
        HapticFeedback.selectionClick();
        setState(() {
          _scale = 1.0;
        });
      },
      onLongPress: () {
        if (widget.editable) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder:
                (context) =>
                    SelectHabitColorSheet(tp: tp, fromCompletionWidget: true),
          );
          return;
        }
        habitProvider.completeHabit(widget.habit.id, context, stateProvider);
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
                    duration:
                        (_hasAnimatedProgress &&
                                getProgressValue() != _lastProgress)
                            ? const Duration(milliseconds: 500)
                            : Duration.zero,
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: _lastProgress,
                      end: getProgressValue(),
                    ),
                    builder: (context, value, _) {
                      // Cache the last progress after the frame so future builds animate from it
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _lastProgress = getProgressValue();
                          _hasAnimatedProgress = true;
                        }
                      });
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
    final tp = context.watch<ThemeProvider>();
    final colorfullness = context.watch<PreferencesProvider>().colorfulness;
    return Center(
      child: Icon(
        Icons.check,
        color:
            widget.habit.completed
                ? widget.habit.getCompletionColor(tp, colorfullness).darken(30)
                : Color(0xFFF8F9FA),
      ),
    );
  }

  // Middle child inside of the container (checkmark or amount/duration)
  Widget getCompletionWidget() {
    if (widget.habit.tracksAmount && !widget.habit.completed) {
      return AmountDisplay(
        habit: widget.habit,
        tp: widget.tp,
        skipped: widget.habit.skipped,
      );
    } else if (widget.habit.tracksDuration && !widget.habit.completed) {
      return DurationDisplay(habit: widget.habit);
    } else {
      return centerIcon();
    }
  }
}
