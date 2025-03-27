import 'package:flutter/material.dart';
import 'package:habitt/generated/assets.gen.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/custom_text_field.dart';
import 'package:habitt/widgets/floating_bottom_button.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/more_options_text.dart';
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
      stateProvider.iconPath = Assets.images.icons.book.path;
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
    final habitProvider = context.watch<HabitProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final localizations = AppLocalizations.of(context)!;

    final stateProvider = context.watch<StateProvider>();
    final nameController = stateProvider.nameController;
    final descController = stateProvider.descController;

    bool canAddHabit() {
      return nameController.text.isNotEmpty;
    }

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
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: nameController,
              builder:
                  (context, value, child) => FloatingBottomButton(
                    showButton: true,
                    enabled: canAddHabit(),
                    onPressed: () {
                      if (!canAddHabit()) return;
                      habitProvider.addHabit(
                        Habit(
                          id: 1,
                          name: nameController.text,
                          description: descController.text,
                          iconPath: stateProvider.iconPath,
                          categoryId: categoryProvider.selectedCategoryId,
                          tag: "No tag",
                          completed: false,
                          amount: stateProvider.habitAmount,
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
            ),
          ],
        ),
      ),
    );
  }
}
