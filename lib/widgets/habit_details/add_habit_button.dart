import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/custom_switcher_wrapper.dart';
import 'package:habitt/widgets/default/default_button.dart';

class AddHabitButton extends StatelessWidget {
  const AddHabitButton({
    super.key,
    required this.nameController,
    required this.habitProvider,
    required this.descController,
    required this.stateProvider,
    required this.categoryProvider,
    required this.localizations,
  });

  final TextEditingController nameController;
  final HabitProvider habitProvider;
  final TextEditingController descController;
  final StateProvider stateProvider;
  final CategoryProvider categoryProvider;
  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    bool canAddHabit() {
      return nameController.text.isNotEmpty;
    }

    int getUniqueId() {
      final now = DateTime.now();
      // Milliseconds since epoch provides the time component
      final timeComponent = now.millisecondsSinceEpoch;

      // Generate a random number between 0 and 999
      final random = Random().nextInt(1000);

      // Combine them. This makes the ID much more unique.
      // The multiplication shifts the time component to make space for the random part.
      return timeComponent * 1000 + random;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: nameController,
      builder: (context, value, child) {
        final enabled = canAddHabit();

        return CustomSwitcherWrapper(
          value: enabled,
          widget: DefaultButton(
            key: const ValueKey("add_habit_button"),
            enabled: enabled,
            onPressed: () {
              if (!canAddHabit()) return;

              habitProvider.addHabit(
                Habit(
                  id: getUniqueId(),
                  name: nameController.text,
                  description: descController.text,
                  iconPath: stateProvider.iconPath,
                  categoryId: stateProvider.habitCategoryId,
                  tag: "No tag",
                  completed: false,
                  skipped: false,
                  amount: stateProvider.habitAmount,
                  amountLabel: stateProvider.habitAmountLabelController.text,
                  amountCompleted: 0,
                  duration: stateProvider.habitDuration.inMinutes,
                  durationCompleted: 0,
                  streak: 0,
                  longestStreak: 0,
                  additional: stateProvider.isAdditional,
                  timeIntervalEnabled: stateProvider.timeIntervalEnabled,
                  timeIntervalStart: stateProvider.timeIntervalStart,
                  timeIntervalEnd: stateProvider.timeIntervalEnd,
                  colorName: stateProvider.habitColorName,
                ),
              );
              Navigator.of(context).pop();

              stateProvider.alertText = "Habit added!";
              stateProvider.toggleAlert(show: true);
            },
            label: localizations.addHabit,
          ),
        );
      },
    );
  }
}
