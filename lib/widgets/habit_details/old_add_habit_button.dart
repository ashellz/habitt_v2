import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/custom_switcher_wrapper.dart';
import 'package:habitt/widgets/default/old_default_button.dart';

class OldAddHabitButton extends StatelessWidget {
  const OldAddHabitButton({
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

    List<String> buildCustomAppearance(int intervalDays) {
      final start = DateTime.now();
      final anchor = DateTime(start.year, start.month, start.day);
      final output = <String>[];
      for (int i = 0; i < 180; i += intervalDays) {
        output.add(
          anchor.add(Duration(days: i)).toIso8601String().split('T').first,
        );
      }
      return output;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: nameController,
      builder: (context, value, child) {
        final enabled = canAddHabit();

        return CustomSwitcherWrapper(
          value: enabled,
          widget: OldDefaultButton(
            key: const ValueKey("add_habit_button"),
            enabled: enabled,
            onPressed: () {
              if (!canAddHabit()) return;
              final loc = AppLocalizations.of(context)!;

              habitProvider.addHabit(
                Habit(
                  id: getUniqueId(),
                  name: nameController.text,
                  description: descController.text,
                  iconPath: stateProvider.iconPath,
                  categoryId: stateProvider.habitCategoryId,
                  tag: loc.noTag,
                  completed: false,
                  skipped: false,
                  amount: stateProvider.habitAmount,
                  amountLabel: stateProvider.habitAmountLabelController.text,
                  amountCompleted: 0,
                  duration: stateProvider.habitDuration.inMinutes,
                  durationCompleted: 0,
                  streak: 0,
                  longestStreak: 0,
                  optional: stateProvider.isOptional,
                  timeIntervalEnabled: stateProvider.timeIntervalEnabled,
                  timeIntervalStart: stateProvider.timeIntervalStart,
                  timeIntervalEnd: stateProvider.timeIntervalEnd,
                  scheduleType: stateProvider.selectedScheduleOption,
                  weeklyTarget: stateProvider.weeklyTarget,
                  monthlyTarget: stateProvider.monthlyTarget,
                  customIntervalDays: stateProvider.customIntervalDays,
                  selectedDaysAWeek:
                      stateProvider.selectedDaysAWeek.toList()..sort(),
                  selectedDaysAMonth:
                      stateProvider.selectedDaysAMonth.toList()..sort(),
                  customAppearance: buildCustomAppearance(
                    stateProvider.customIntervalDays,
                  ),
                  timesCompletedThisWeek: 0,
                  timesCompletedThisMonth: 0,
                  lastCustomUpdate: DateTime.now().toUtc(),
                  colorName: stateProvider.habitColorName,
                ),
              );
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }

              stateProvider.alertText = loc.habitAdded;
              stateProvider.toggleAlert(show: true);
            },
            label: localizations.addHabit,
          ),
        );
      },
    );
  }
}
