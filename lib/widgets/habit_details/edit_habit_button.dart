import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/pages/other_pages/edit_habit_page.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/color_converting.dart';
import 'package:provider/provider.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:habitt/l10n/app_localizations.dart';

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
              widget.habit.trackingType =
                  stateProvider.selectedHabitTrackingType;
              widget.habit.iconPath = stateProvider.iconPath;
              widget.habit.optional = stateProvider.isOptional;

              widget.habit.timeIntervalEnabled =
                  stateProvider.timeIntervalEnabled;
              widget.habit.timeIntervalStart = stateProvider.timeIntervalStart;
              widget.habit.timeIntervalEnd = stateProvider.timeIntervalEnd;
              widget.habit.scheduleType = stateProvider.selectedScheduleOption;
              widget.habit.weeklyTarget = stateProvider.weeklyTarget;
              widget.habit.monthlyTarget = stateProvider.monthlyTarget;
              widget.habit.customIntervalDays =
                  stateProvider.customIntervalDays;
              widget.habit.selectedDaysAWeek =
                  stateProvider.selectedDaysAWeek.toList()..sort();
              widget.habit.selectedDaysAMonth =
                  stateProvider.selectedDaysAMonth.toList()..sort();
              if (widget.habit.scheduleType == ScheduleType.custom) {
                final start = DateTime.now();
                final anchor = DateTime(start.year, start.month, start.day);
                final appearance = <String>[];
                for (int i = 0; i < 180; i += widget.habit.customIntervalDays) {
                  appearance.add(
                    anchor
                        .add(Duration(days: i))
                        .toIso8601String()
                        .split('T')
                        .first,
                  );
                }
                widget.habit.customAppearance = appearance;
                widget.habit.lastCustomUpdate = DateTime.now().toUtc();
              }

              final tp = context.read<ThemeProvider>();
              widget.habit.colorName = stateProvider.habitColorName;
              widget.habit.color = colorToHex(
                stateProvider.getHabitColor(tp) ?? tp.primaryColor,
              );

              habitProvider.updateHabit(widget.habit);

              Navigator.of(context).pop();

              stateProvider.alertText = AppLocalizations.of(context)!.changesSaved;
              stateProvider.toggleAlert(show: true);
            },
            label: localizations.saveChanges,
          ),
    );
  }
}
