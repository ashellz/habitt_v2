import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/habit_details/add_habit_button.dart';
import 'package:habitt/widgets/habit_details/additional_task_switch.dart';
import 'package:habitt/widgets/default/default_text_field.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/habit_details/scheduling_and_alerts.dart';
import 'package:habitt/widgets/habit_details/selected_habit_display.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/habit_details/more_options_text.dart';
import 'package:habitt/widgets/default/nav_back_button.dart';
import 'package:habitt/widgets/habit_details/select_habit_type_options.dart';
import 'package:provider/provider.dart';

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
    final tp = context.watch<ThemeProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final localizations = AppLocalizations.of(context)!;
    final stateProvider = context.watch<StateProvider>();
    final nameController = stateProvider.nameController;
    final descController = stateProvider.descController;

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: GradientBackground(
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                children: [
                  ListView(
                    children: [
                      NavBackButton(tp: tp),
                      Text(
                        localizations.newHabit,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: tp.primaryColor,
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
                        topPadding: 16,
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
                      SchedulingAndAlerts(tp: tp),
                      AdditionalTaskSwitch(
                        tp: tp,
                        stateProvider: stateProvider,
                      ),
                      SizedBox(height: 68),
                    ],
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                    left: 0,
                    right: 0,
                    child: AddHabitButton(
                      nameController: nameController,
                      habitProvider: habitProvider,
                      descController: descController,
                      stateProvider: stateProvider,
                      categoryProvider: categoryProvider,
                      localizations: localizations,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
