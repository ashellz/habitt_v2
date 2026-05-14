import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:provider/provider.dart';

class OldDeleteHabitDialog extends StatelessWidget {
  const OldDeleteHabitDialog({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return OldDefaultDialog(
      danger: true,
      title: "Delete '${habit.name}'?",
      desc: AppLocalizations.of(context)!.areYouSureYouWantToDeleteThisHabit,
      leftButtonOutlined: true,
      leftButtonText: localizations.cancel,
      rightButtonText: AppLocalizations.of(context)!.delete,
      rightButtonCallback: () {
        context.read<HabitProvider>().removeHabit(habit, context);
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        final stateProvider = context.read<StateProvider>();
        stateProvider.alertText = AppLocalizations.of(context)!.habitDeleted;
        stateProvider.toggleAlert(show: true);
      },
    );
  }
}
