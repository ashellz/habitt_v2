import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_spinbox.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/amount_display.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/duration_display.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
                    widget.habit.completed) {
                  habitProvider.completeHabit(widget.habit.id);
                } else {
                  // TODO: Open dialog for selecting amount/duration completion

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
                    tween: Tween<double>(
                      begin: 0,
                      end:
                          // Really complicated logic here but it works
                          // Basically checks if habit has amount or duration
                          // If not its filled from 0 to 1 if completed or not
                          // Otherwise fills it by amount or duration completed accordingly
                          widget.habit.amount == 0 &&
                                      widget.habit.duration == 0 ||
                                  widget.habit.completed
                              ? widget.habit.completed
                                  ? 1
                                  : 0
                              : widget.habit.amount > 1
                              ? widget.habit.amountCompleted /
                                  widget.habit.amount
                              : widget.habit.durationCompleted /
                                  widget.habit.duration,
                    ),
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        color:
                            widget
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
        widget.habit.completed ? Icons.check : Icons.close,
        color: widget.colorProvider.backgroundColor,
      ),
    );
  }

  // Middle child inside of the container (checkmark or amount/duration)
  Widget getCompletionWidget() {
    if (widget.habit.amount > 0 && !widget.habit.completed) {
      return AmountDisplay(
        habit: widget.habit,
        colorProvider: widget.colorProvider,
      );
    } else if (widget.habit.duration > 0 && !widget.habit.completed) {
      return DurationDisplay(habit: widget.habit);
    } else {
      return centerIcon();
    }
  }
}

class CompletionDialog extends StatelessWidget {
  const CompletionDialog({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final habitProvider = context.read<HabitProvider>();
    final stateProvider = context.watch<StateProvider>();

    HabitType type = HabitType.none;

    if (habit.amount > 1) {
      type = HabitType.amount;
    } else if (habit.duration > 0) {
      type = HabitType.duration;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          content: CompletionDialogContent(
            habit: habit,
            stateProvider: stateProvider,
            type: type,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: Text(localizations.cancel),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(localizations.done),
                  onPressed: () {
                    if (type == HabitType.amount) {
                      // If entered amount is equal to the amount of the habit, complete the habit
                      // Else if it is smaller than the amount of the habit, apply the amount completed
                      habitProvider.updateHabitAmountCompleted(
                        habit.id,
                        stateProvider.habitAmount,
                      );
                    } else {
                      // If entered duration is equal to the duration of the habit, complete the habit
                      // Else if it is smaller than the duration of the habit, apply the duration completed
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class CompletionDialogContent extends StatefulWidget {
  const CompletionDialogContent({
    super.key,
    required this.habit,
    required this.stateProvider,
    required this.type,
  });

  final Habit habit;
  final StateProvider stateProvider;
  final HabitType type;

  @override
  State<CompletionDialogContent> createState() =>
      _CompletionDialogContentState();
}

class _CompletionDialogContentState extends State<CompletionDialogContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.type == HabitType.amount) {
        widget.stateProvider.habitAmount = widget.habit.amountCompleted;
      } else {
        widget.stateProvider.habitDuration = Duration(
          hours: widget.habit.durationCompleted ~/ 60,
          minutes: widget.habit.durationCompleted % 60,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    int amount = widget.habit.amount;
    int minutes = widget.habit.duration % 60;
    int hours = widget.habit.duration ~/ 60;
    int completedHours = widget.habit.durationCompleted ~/ 60;
    int completedMinutes = widget.habit.durationCompleted % 60;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            if (widget.habit.amount > 1)
              Column(
                children: [
                  CustomSpinBox(
                    labelText: widget.habit.amountName,
                    min: 0,
                    max: amount.toDouble(),
                    value: widget.stateProvider.habitAmount.toDouble(),
                    onChanged: (value) {
                      widget.stateProvider.habitAmount = value.toInt();
                    },
                  ),
                ],
              )
            else
              Column(
                children: [
                  if (widget.habit.duration > 60)
                    CustomSpinBox(
                      labelText: localizations.hours,
                      min: 0,
                      max: hours.toDouble(),
                      value: completedHours.toDouble(),
                      onChanged: (value) {
                        /*

                      // Update the duration in the provider
                      context.read<DataProvider>().setDurationValueHours(
                        value.toInt(),
                      );

                      // Use addPostFrameCallback to ensure the updated value is retrieved after the state change
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final updatedDurationValueHours =
                            context.read<DataProvider>().theDurationValueHours;

                        if (updatedDurationValueHours ==
                            (habitBox.getAt(index)!.duration ~/ 60)) {
                          if (theDurationValueMinutes >
                              (habitBox.getAt(index)!.duration % 60)) {
                            context
                                .read<DataProvider>()
                                .setDurationValueMinutes(
                                  (habitBox.getAt(index)!.duration % 60),
                                );
                          }
                        }
                      });
                        */
                      },
                    ),
                  if (widget.habit.duration > 60) const SizedBox(height: 10),
                  CustomSpinBox(
                    labelText: localizations.minutes,
                    min: 0,
                    max:
                        completedHours.toDouble() < hours
                            ? 59
                            : minutes.toDouble(),
                    value: completedMinutes.toDouble(),
                    onChanged: (value) {
                      /*

                      context.read<DataProvider>().setDurationValueMinutes(
                        value.toInt(),
                      );
                        */
                    },
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
