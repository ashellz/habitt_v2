import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_spinbox.dart';
import 'package:habitt/widgets/default_dialog.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class DurationCompletionDialog extends StatelessWidget {
  const DurationCompletionDialog({
    super.key,
    required this.habit,
    required this.day,
  });

  final Habit habit;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final habitProvider = context.read<HabitProvider>();
    final stateProvider = context.watch<StateProvider>();

    return DefaultDialog(
      leftButtonText: localizations.cancel,
      leftButtonOutlined: true,
      rightButtonText: localizations.done,
      rightButtonCallback: () {
        // If nothing changed then don't update unnecessarily
        if (habit.durationCompleted == stateProvider.habitDuration.inMinutes) {
          Navigator.pop(context);
          return;
        }

        habitProvider.updateHabitDurationCompleted(
          habit.id,
          stateProvider.habitDuration.inMinutes,
          context,
          day: day,
        );

        Navigator.pop(context);
      },
      content: DurationCompletionDialogContent(
        habit: habit,
        stateProvider: stateProvider,
      ),
    );
  }
}

// Content above buttons

class DurationCompletionDialogContent extends StatefulWidget {
  const DurationCompletionDialogContent({
    super.key,
    required this.habit,
    required this.stateProvider,
  });

  final Habit habit;
  final StateProvider stateProvider;

  @override
  State<DurationCompletionDialogContent> createState() =>
      _DurationCompletionDialogContentState();
}

class _DurationCompletionDialogContentState
    extends State<DurationCompletionDialogContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sets the initial amount or duration

      widget.stateProvider.habitDuration = Duration(
        hours: widget.habit.durationCompleted ~/ 60,
        minutes: widget.habit.durationCompleted % 60,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    int minutes = widget.habit.duration % 60;
    int hours = widget.habit.duration ~/ 60;

    return Column(
      children: [
        Column(
          children: [
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
