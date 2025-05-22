import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_text_field.dart';
import 'package:habitt/widgets/floating_bottom_button.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/more_options_text.dart';
import 'package:habitt/widgets/nav_back_button.dart';
import 'package:habitt/widgets/select_habit_type_options.dart';
import 'package:habitt/widgets/selected_habit_display.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditHabitPage extends StatefulWidget {
  const EditHabitPage({super.key, required this.habit});

  final Habit habit;

  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  bool shouldReset = true;
  late final Duration initialDuration;
  late final int initialAmount;

  @override
  void initState() {
    super.initState();
    final categoryProvider = context.read<CategoryProvider>();
    final stateProvider = context.read<StateProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sets initial habit amount and duration
      initialDuration = Duration(minutes: widget.habit.duration);
      initialAmount = widget.habit.amount;

      // Loads habit values
      categoryProvider.selectCategory(widget.habit.categoryId);
      stateProvider.nameController.text = widget.habit.name;
      stateProvider.descController.text = widget.habit.description;
      stateProvider.habitAmount = widget.habit.amount;
      stateProvider.habitDuration = Duration(minutes: widget.habit.duration);
      stateProvider.habitAmountLabelController.text = widget.habit.amountLabel;
      stateProvider.iconPath = widget.habit.iconPath;
    });
  }

  void onTap() {
    if (shouldReset) {
      final stateProvider = context.read<StateProvider>();
      stateProvider.nameController.clear();
      shouldReset = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;

    final stateProvider = context.watch<StateProvider>();
    final nameController = stateProvider.nameController;
    final descController = stateProvider.descController;

    bool canEditHabit() {
      return nameController.text.isNotEmpty;
    }

    return Scaffold(
      backgroundColor: colorProvider.backgroundColor,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  NavBackButton(colorProvider: colorProvider),
                  Text(
                    localizations.editHabit,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: colorProvider.colorScheme.vividColor,
                    ),
                  ),
                  SelectedHabitDisplay(
                    completed: widget.habit.completed,
                    amountCompleted: widget.habit.amountCompleted,
                    durationCompleted: widget.habit.durationCompleted,
                    streak: widget.habit.streak,
                  ),
                  CategoriesList(
                    topPadding: 8,
                    showAll: false,
                    standardColor: true,
                    habitsCount: false,
                  ),
                  CustomTextField(
                    title: localizations.habitName,
                    controller: nameController,
                    onTap: onTap,
                  ),
                  CustomTextField(
                    topPadding: 16,
                    title: localizations.notes,
                    controller: descController,
                    maxLines: 5,
                  ),
                  MoreOptionsText(localizations: localizations),
                  SelectHabitTypeOptions(),
                ],
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: nameController,
              builder:
                  (context, value, child) => FloatingBottomButton(
                    showButton: true,
                    enabled: canEditHabit(),
                    onPressed: () {
                      if (!canEditHabit()) return;

                      // Edit habit in state and database
                      final HabitProvider habitProvider =
                          context.read<HabitProvider>();
                      final CategoryProvider categoryProvider =
                          context.read<CategoryProvider>();

                      // Checks for amount/duration changes

                      if (stateProvider.habitAmount != initialAmount) {
                        widget.habit.resetCompletion();
                        widget.habit.amount = stateProvider.habitAmount;
                      } else if (stateProvider.habitDuration !=
                          initialDuration) {
                        widget.habit.resetCompletion();
                        widget.habit.duration =
                            stateProvider.habitDuration.inMinutes;
                      }

                      widget.habit.name = nameController.text;
                      widget.habit.description = descController.text;
                      widget.habit.categoryId =
                          categoryProvider.selectedCategoryId;
                      widget.habit.amountLabel =
                          stateProvider.habitAmountLabelController.text;
                      widget.habit.iconPath = stateProvider.iconPath;

                      habitProvider.updateHabit(widget.habit);

                      Navigator.of(context).pop();
                    },
                    label: localizations.saveChanges,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
