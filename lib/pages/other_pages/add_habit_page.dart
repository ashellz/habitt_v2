import 'package:flutter/material.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_text_field.dart';
import 'package:habitt/widgets/habit_widget/habit_widget.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/more_options_text.dart';
import 'package:habitt/widgets/select_habit_type_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddHabitPage extends StatefulWidget {
  const AddHabitPage({super.key});

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  bool shouldReset = true;

  @override
  void initState() {
    super.initState();
    final categoryProvider = context.read<CategoryProvider>();
    final stateProvider = context.read<StateProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context)!;
      categoryProvider.selectCategory(1);
      stateProvider.nameController.text = localizations.habitName;
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

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  Text(
                    localizations.newHabit,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: colorProvider.colorScheme.darkerStandardColor,
                    ),
                  ),
                  SelectedHabitDisplay(),
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
          ],
        ),
      ),
    );
  }
}

class SelectedHabitDisplay extends StatelessWidget {
  const SelectedHabitDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();
    final descController = stateProvider.descController;
    final nameController = stateProvider.nameController;
    final amount = stateProvider.habitAmount;
    final duration = stateProvider.habitDuration.inMinutes;
    final iconPath = stateProvider.iconPath;

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: descController,
        builder:
            (context, value, child) => ValueListenableBuilder<TextEditingValue>(
              valueListenable: nameController,
              builder:
                  (context, value, child) => HabitWidget(
                    name: value.text,
                    desc: descController.text,
                    iconPath: iconPath,
                    streak: 0,
                    amount: amount,
                    duration: duration,
                    amountCompleted: 0,
                    durationCompleted: 0,
                    completed: false,
                    editable: true,
                  ),
            ),
      ),
    );
  }
}
