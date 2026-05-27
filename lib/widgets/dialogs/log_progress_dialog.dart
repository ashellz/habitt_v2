import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/amount_progress_input.dart';
import 'package:habitt/widgets/habit_widget/progress_inputs/duration_progress_input.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

enum ProgressType { amount, duration }

class LogProgressDialog extends StatelessWidget {
  const LogProgressDialog({
    super.key,
    required this.progressType,
    required this.habit,
    this.dayOverride,
  });

  final ProgressType progressType;
  final Habit habit;
  final DateTime? dayOverride;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    final title =
        progressType == ProgressType.amount ? loc.logProgress : loc.logDuration;
    final desc =
        progressType == ProgressType.amount
            ? loc.howMuchDidYouCompleteToday
            : loc.howMuchTimeDidYouSpendOnThisHabitToday;

    return NewDefaultDialog(
      title: title,
      desc: desc,
      primaryButtonLabel: loc.save,
      onPrimaryButtonPressed: () {
        final habitProvider = context.read<HabitProvider>();
        final stateProvider = context.read<StateProvider>();

        if (progressType == ProgressType.amount) {
          if (habit.amountCompleted == stateProvider.habitAmount) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            ;
            return;
          }

          habitProvider.updateHabitAmountCompleted(
            habit.id,
            stateProvider.habitAmount,
            context,
            dayOverride: dayOverride,
          );
        }

        if (progressType == ProgressType.duration) {
          if (habit.durationCompleted ==
              stateProvider.habitDuration.inMinutes) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            ;
            return;
          }

          habitProvider.updateHabitDurationCompleted(
            habit.id,
            stateProvider.habitDuration.inMinutes,
            context,
            dayOverride: dayOverride,
          );
        }

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ;
      },
      child: progress(cp, loc),
    );
  }

  Widget progress(ColorProvider cp, AppLocalizations loc) {
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
        target(cp, loc),
      ],
    );
  }

  Row target(ColorProvider cp, AppLocalizations loc) {
    String getTargetText() {
      if (progressType == ProgressType.amount) {
        return "${habit.amount} ${resolveAmountLabelForValue(habit.amountLabel.isEmpty ? loc.times : habit.amountLabel, habit.amount, loc)}";
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
          loc.target,
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
