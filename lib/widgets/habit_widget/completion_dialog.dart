import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_capitalized_first.dart';
import 'package:habitt/widgets/custom_spinbox.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class CompletionDialog extends StatelessWidget {
  const CompletionDialog({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final habitProvider = context.read<HabitProvider>();
    final stateProvider = context.watch<StateProvider>();
    final colorProvider = context.watch<ColorProvider>();

    HabitType type = HabitType.none;

    if (habit.amount > 1) {
      type = HabitType.amount;
    } else if (habit.duration > 0) {
      type = HabitType.duration;
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: colorProvider.backgroundColor,
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
                  child: Text(
                    localizations.cancel,
                    style: TextStyle(
                      color: colorProvider.colorScheme.vividColor,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(
                    localizations.done,
                    style: TextStyle(
                      color: colorProvider.colorScheme.vividColor,
                    ),
                  ),
                  onPressed: () {
                    if (type == HabitType.amount) {
                      // If nothing changed then don't update unnecessarily
                      if (habit.amountCompleted == stateProvider.habitAmount) {
                        Navigator.pop(context);
                        return;
                      }

                      habitProvider.updateHabitAmountCompleted(
                        habit.id,
                        stateProvider.habitAmount,
                      );
                    } else {
                      // If nothing changed then don't update unnecessarily
                      if (habit.durationCompleted ==
                          stateProvider.habitDuration.inMinutes) {
                        Navigator.pop(context);
                        return;
                      }

                      habitProvider.updateHabitDurationCompleted(
                        habit.id,
                        stateProvider.habitDuration.inMinutes,
                      );
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
      // Sets the initial amount or duration
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          children: [
            if (widget.habit.amount > 1)
              Column(
                children: [
                  CustomSpinBox(
                    labelText: capitalizeFirst(widget.habit.amountLabel),
                    min: 0,
                    max: amount.toDouble(),
                    value: widget.stateProvider.habitAmount.toDouble(),
                    onChanged: (value) {
                      // Sets the new amount
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
                      value:
                          widget.stateProvider.habitDuration.inHours.toDouble(),
                      onChanged: (value) {
                        final int newMinutes =
                            widget.stateProvider.habitDuration.inMinutes % 60;

                        // Sets the new duration
                        widget.stateProvider.habitDuration = Duration(
                          hours: value.toInt(),
                          minutes: newMinutes,
                        );

                        // If the hours are maxed out, lowers minutes if they're over the max amount
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (widget.stateProvider.habitDuration.inHours ==
                              hours) {
                            if (newMinutes > minutes) {
                              widget.stateProvider.habitDuration = Duration(
                                hours: value.toInt(),
                                minutes: minutes,
                              );
                            }
                          }
                        });
                      },
                    ),
                  if (widget.habit.duration > 60) const SizedBox(height: 10),
                  CustomSpinBox(
                    labelText: localizations.minutes,
                    min: 0,
                    max: // If hour is maxed out, sets max to max minutes, else 59
                        widget.stateProvider.habitDuration.inHours.toDouble() <
                                hours
                            ? 59
                            : minutes.toDouble(),
                    value: widget.stateProvider.habitDuration.inMinutes % 60,
                    onChanged: (value) {
                      // Sets the new duration
                      widget.stateProvider.habitDuration = Duration(
                        hours: widget.stateProvider.habitDuration.inHours,
                        minutes: value.toInt(),
                      );
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
