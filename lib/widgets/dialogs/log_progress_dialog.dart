import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/amount_progress_input.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/duration_progress_input.dart';
import 'package:provider/provider.dart';

enum ProgressType { amount, duration }

class LogProgressDialog extends StatelessWidget {
  const LogProgressDialog({
    super.key,
    required this.progressType,
    required this.habit,
  });

  final ProgressType progressType;
  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    final title =
        progressType == ProgressType.amount ? "Log progress" : "Log duration";
    final desc =
        progressType == ProgressType.amount
            ? "How much did you complete today?"
            : "How much time did you spend on this habit today?";

    return NewDefaultDialog(
      title: title,
      desc: desc,
      primaryButtonLabel: "Save",
      onPrimaryButtonPressed: () {
        final habitProvider = context.read<HabitProvider>();
        final stateProvider = context.read<StateProvider>();

        if (progressType == ProgressType.amount) {
          if (habit.amountCompleted == stateProvider.habitAmount) {
            Navigator.pop(context);
            return;
          }

          habitProvider.updateHabitAmountCompleted(
            habit.id,
            stateProvider.habitAmount,
            context,
          );
        }

        if (progressType == ProgressType.duration) {
          if (habit.durationCompleted ==
              stateProvider.habitDuration.inMinutes) {
            Navigator.pop(context);
            return;
          }

          habitProvider.updateHabitDurationCompleted(
            habit.id,
            stateProvider.habitDuration.inMinutes,
            context,
          );
        }

        Navigator.pop(context);
      },
      child: progress(cp),
    );
  }

  Widget progress(ColorProvider cp) {
    return Column(
      spacing: 16,
      children: [
        if (progressType == ProgressType.amount)
          AmountProgressInput(
            amount: habit.amount,
            amountCompleted: habit.amountCompleted,
          )
        else
          DurationProgressInput(
            duration: habit.duration,
            durationCompleted: habit.durationCompleted,
          ),
        target(cp),
      ],
    );
  }

  Row target(ColorProvider cp) {
    String getTargetText() {
      if (progressType == ProgressType.amount) {
        return "${habit.amount} ${habit.amountLabel.isEmpty ? "times" : habit.amountLabel}";
      } else {
        final hours = habit.duration ~/ 60;
        final minutes = habit.duration % 60;

        return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Target:',
          style: TextStyle(
            color: cp.text,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SvgPicture.asset("assets/images/new-svg/clock.svg"),
            Text(
              getTargetText(),
              style: TextStyle(
                color: cp.text,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
