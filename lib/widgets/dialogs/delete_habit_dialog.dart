import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/pages/other_pages/edit_habit_page.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/default_dialog.dart';
import 'package:provider/provider.dart';

class DeleteHabitDialog extends StatelessWidget {
  const DeleteHabitDialog({super.key, required this.widget});

  final EditHabitPage widget;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return DefaultDialog(
      danger: true,
      title: "Delete '${widget.habit.name}'?",
      desc: "Are you sure you want to delete this habit?",
      leftButtonOutlined: true,
      leftButtonText: localizations.cancel,
      rightButtonText: "Delete",
      rightButtonCallback: () {
        context.read<HabitProvider>().removeHabit(widget.habit);
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        final stateProvider = context.read<StateProvider>();
        stateProvider.alertText = "Habit deleted!";
        stateProvider.toggleAlert(show: true);
      },
    );
  }
}
