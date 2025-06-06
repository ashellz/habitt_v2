import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_text_field.dart';
import 'package:habitt/widgets/default_button.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/more_options_text.dart';
import 'package:habitt/widgets/nav_back_button.dart';
import 'package:habitt/widgets/select_habit_type_options.dart';
import 'package:habitt/widgets/selected_habit_display.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  @override
  void initState() {
    super.initState();
    final stateProvider = context.read<StateProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stateProvider.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final localizations = AppLocalizations.of(context)!;
    final stateProvider = context.watch<StateProvider>();
    final nameController = stateProvider.nameController;
    final descController = stateProvider.descController;

    return Scaffold(
      backgroundColor: colorProvider.backgroundColor,
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              NavBackButton(colorProvider: colorProvider),
              Text(
                localizations.newHabit,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: colorProvider.colorScheme.vividColor,
                ),
              ),
              SelectedHabitDisplay(
                streak: 0,
                amountCompleted: 0,
                durationCompleted: 0,
                completed: false,
              ),
              CategoriesList(
                useHabitCategory: true,
                topPadding: 8,
                showAll: false,
                standardColor: true,
                habitsCount: false,
              ),
              CustomTextField(
                title: localizations.habitName,
                controller: nameController,
              ),
              CustomTextField(
                topPadding: 16,
                title: localizations.notes,
                controller: descController,
                maxLines: 5,
              ),
              MoreOptionsText(localizations: localizations),
              SelectHabitTypeOptions(),
              AddHabitButton(
                nameController: nameController,
                habitProvider: habitProvider,
                descController: descController,
                stateProvider: stateProvider,
                categoryProvider: categoryProvider,
                localizations: localizations,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      int id = 0;
      while (habitProvider.habits.any((h) => h.id == id)) {
        id++;
      }
      return id;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: nameController,
      builder:
          (context, value, child) => DefaultButton(
            enabled: canAddHabit(),
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
                  amount: stateProvider.habitAmount,
                  amountLabel: stateProvider.habitAmountLabelController.text,
                  amountCompleted: 0,
                  duration: stateProvider.habitDuration.inMinutes,
                  durationCompleted: 0,
                  streak: 0,
                ),
              );
              Navigator.of(context).pop();
            },
            label: localizations.addHabit,
          ),
    );
  }
}
