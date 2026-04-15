import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/delete_habit_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/dialogs/delete_habit_dialog_name_confirm.dart';
import 'package:provider/provider.dart';

Future<void> showDeleteHabitFlow(Habit habit, BuildContext context) async {
  final cp = context.read<ColorProvider>();

  final shouldContinue = await showDialogSheet(
    context: context,
    builder:
        (dialogContext) =>
            DeleteHabitDialog(habit: habit, dialogContext: dialogContext),
  );

  if (shouldContinue != true || !context.mounted) {
    return;
  }

  final typedNameConfirmed = await showDialogSheet(
    context: context,
    builder:
        (dialogContext) => DeleteHabitDialogNameConfirm(
          expectedHabitName: habit.name,
          primaryButtonColor: cp.fail,
          onConfirmed: () {
            Navigator.of(dialogContext).pop(true);
          },
        ),
  );

  if (typedNameConfirmed != true || !context.mounted) {
    return;
  }

  context.read<HabitProvider>().removeHabit(habit, context);

  if (!context.mounted) {
    return;
  }

  Navigator.of(context).pop();
}
