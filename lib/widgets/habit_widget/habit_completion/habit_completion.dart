import 'dart:ui';

import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/widgets/default/blur_circle_button.dart';
import 'package:habitt/widgets/default/glass_blur_container.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/default/number_picker.dart';
import 'package:habitt/widgets/dialogs/select_time_dialog.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/duration_completion_dialog.dart';
import 'package:habitt/widgets/habit_widget/completion_dialogs/enter_amount_slider_dialog.dart';
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

  Color getCompletionColor() {
    final habit = widget.habit;
    final tp = widget.tp;
    final colorfulness = context.watch<PreferencesProvider>().colorfulness;

    if (habit.skipped) {
      return tp.borderColor.darken(tp.isDark ? 0 : 45);
    }

    switch (colorfulness) {
      case Colorfulness.tinted:
        return tp.primaryColor;
      case Colorfulness.standard:
        return tp.successColor;
      case Colorfulness.colorful:
        return habit.getColor ?? tp.successColor;
    }
  }

  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.read<HabitProvider>();
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
                    showDialog(
                      context: context,
                      builder:
                          (context) => DurationCompletionDialog(
                            habit: widget.habit,
                            day: widget.isToday ? DateTime.now() : focusedDay,
                          ),
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
                        color: getCompletionColor(),
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

class DurationCompletionDialog extends StatefulWidget {
  const DurationCompletionDialog({
    super.key,
    required this.habit,
    required this.day,
  });

  final Habit habit;
  final DateTime day;

  @override
  State<DurationCompletionDialog> createState() =>
      _DurationCompletionDialogState();
}

class _DurationCompletionDialogState extends State<DurationCompletionDialog> {
  FixedExtentScrollController hoursController = FixedExtentScrollController();
  FixedExtentScrollController minutesController = FixedExtentScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sets the initial amount or duration
      final stateProvider = context.read<StateProvider>();
      stateProvider.habitDuration = Duration(
        hours: widget.habit.durationCompleted ~/ 60,
        minutes: widget.habit.durationCompleted % 60,
      );
    });

    setState(() {
      hoursController = FixedExtentScrollController(
        initialItem: widget.habit.durationCompleted ~/ 60,
      );
      minutesController = FixedExtentScrollController(
        initialItem: widget.habit.durationCompleted % 60,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final sp = context.watch<StateProvider>();
    final width = MediaQuery.of(context).size.width - 200;

    int minutes = widget.habit.duration % 60;
    int hours = widget.habit.duration ~/ 60;

    return Dialog(
      backgroundColor:
          Colors.transparent, // Important for the blur to show through
      insetPadding: EdgeInsets.zero,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(width: 8 + 50),
              GlassFeelContainer(
                width: width,
                child: Column(
                  children: [
                    NumberPicker(
                      looping: false,
                      maxHours: hours,
                      maxMinutes:
                          sp.habitDuration.inHours < hours ? 59 : minutes,
                      hoursController: hoursController,
                      minutesController: minutesController,
                      width: width,
                      onChangedHours: (int selectedHours) {
                        final currentDuration = sp.habitDuration;
                        sp.habitDuration = Duration(
                          hours: selectedHours,
                          minutes: currentDuration.inMinutes % 60,
                        );
                        // putting minutes to max if hours are maxed out
                        if (selectedHours == hours) {
                          if (sp.habitDuration.inMinutes % 60 > minutes) {
                            sp.habitDuration = Duration(
                              hours: selectedHours,
                              minutes: minutes,
                            );
                          }
                        }
                      },
                      onChangedMinutes: (int selectedMinutes) {
                        final currentDuration = sp.habitDuration;
                        sp.habitDuration = Duration(
                          hours: currentDuration.inHours,
                          minutes: selectedMinutes,
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  CircleButton(
                    cnIcon: CNSymbol('checkmark', size: 20),
                    tp: tp,
                    icon: Icon(Icons.check, color: Colors.white),
                    color: tp.primaryColor,
                    onPressed: () {
                      // If nothing changed then don't update unnecessarily
                      if (widget.habit.durationCompleted ==
                          sp.habitDuration.inMinutes) {
                        Navigator.pop(context);
                        return;
                      }

                      final habitProvider = context.read<HabitProvider>();
                      habitProvider.updateHabitDurationCompleted(
                        widget.habit.id,
                        sp.habitDuration.inMinutes,
                        context,
                        day: widget.day,
                      );

                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 4),
                  CircleButton(
                    cnIcon: CNSymbol('xmark', size: 20),
                    tp: tp,
                    icon: Icon(Icons.close, color: tp.primaryTextColor),
                    color: tp.surfaceColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
