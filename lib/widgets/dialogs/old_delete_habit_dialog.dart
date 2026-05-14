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
    final loc = AppLocalizations.of(context)!;

    return OldDefaultDialog(
      danger: true,
      title: "Delete '${habit.name}'?",
      desc: loc.areYouSureYouWantToDeleteThisHabit,
      leftButtonOutlined: true,
      leftButtonText: loc.cancel,
      rightButtonText: loc.delete,
      rightButtonCallback: () {
        context.read<HabitProvider>().removeHabit(habit, context);
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        final stateProvider = context.read<StateProvider>();
        stateProvider.alertText = loc.habitDeleted;
        stateProvider.toggleAlert(show: true);
      },
    );
  }
}
