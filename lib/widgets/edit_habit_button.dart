import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/pages/other_pages/edit_habit_page.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default_button.dart';
import 'package:provider/provider.dart';

class EditHabitButton extends StatelessWidget {
  const EditHabitButton({
    super.key,
    required this.nameController,
    required this.stateProvider,
    required this.initialAmount,
    required this.widget,
    required this.initialDuration,
    required this.descController,
    required this.localizations,
  });

  final TextEditingController nameController;
  final StateProvider stateProvider;
  final int initialAmount;
  final EditHabitPage widget;
  final Duration initialDuration;
  final TextEditingController descController;
  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    bool canEditHabit() {
      return nameController.text.isNotEmpty;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: nameController,
      builder:
          (context, value, child) => DefaultButton(
            enabled: canEditHabit(),
            onPressed: () {
              if (!canEditHabit()) return;

              // Edit habit in state and database
              final HabitProvider habitProvider = context.read<HabitProvider>();

              // Checks for amount/duration changes

              if (stateProvider.habitAmount != initialAmount) {
                widget.habit.resetCompletion();
                widget.habit.amount = stateProvider.habitAmount;
              } else if (stateProvider.habitDuration != initialDuration) {
                widget.habit.resetCompletion();
                widget.habit.duration = stateProvider.habitDuration.inMinutes;
              }

              widget.habit.name = nameController.text;
              widget.habit.description = descController.text;
              widget.habit.categoryId = stateProvider.habitCategoryId;
              widget.habit.amountLabel =
                  stateProvider.habitAmountLabelController.text;
              widget.habit.iconPath = stateProvider.iconPath;
              widget.habit.additional = stateProvider.isAdditional;

              widget.habit.timeIntervalEnabled =
                  stateProvider.timeIntervalEnabled;
              widget.habit.timeIntervalStart = stateProvider.timeIntervalStart;
              widget.habit.timeIntervalEnd = stateProvider.timeIntervalEnd;

              habitProvider.updateHabit(widget.habit);

              Navigator.of(context).pop();

              stateProvider.alertText = "Changes saved!";
              stateProvider.toggleAlert(show: true);
            },
            label: localizations.saveChanges,
          ),
    );
  }
}
