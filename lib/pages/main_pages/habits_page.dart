import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/pages/other_pages/add_habit_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/habit_widget/habit_widget.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/habits_page/category_title.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:habitt/widgets/habits_page/habits_completed/habits_completed_widget.dart';
import 'package:provider/provider.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorProvider.colorScheme.darkerStandardColor,
        onPressed:
            () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => AddHabitPage()))
                .whenComplete(() {
                  // Reset the state provider
                  if (!context.mounted) return;
                  final stateProvider = context.read<StateProvider>();
                  stateProvider.reset();

                  // Reset the category provider
                  final categoryProvider = context.read<CategoryProvider>();
                  categoryProvider.selectCategory(0);
                }),
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: [
              Greeting(),
              CategoriesList(),
              HabitsCompletedWidget(),
              Habits(),
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class Habits extends StatelessWidget {
  const Habits({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final habits = habitProvider.habits;

    final ColorProvider colorProvider = context.watch<ColorProvider>();
    if (habits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Text(
          "No habits yet.",
          style: TextStyle(color: colorProvider.mutedTextColor),
        ),
      );
    }

    if (categoryProvider.selectedCategoryId != 0) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: HabitCategory(
              category: categoryProvider.categories.firstWhere(
                (c) => c.id == categoryProvider.selectedCategoryId,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        for (final category in categoryProvider.categories)
          if (getCategoryLength(category, context) > 0)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: HabitCategory(category: category),
            ),
      ],
    );
  }
}

class HabitCategory extends StatefulWidget {
  const HabitCategory({super.key, required this.category});

  final Category category;

  @override
  State<HabitCategory> createState() => _HabitCategoryState();
}

class _HabitCategoryState extends State<HabitCategory> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      setState(() {
        _opacity = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final categoryHabits =
        habitProvider.habits
            .where((habit) => habit.categoryId == widget.category.id)
            .toList();

    if (categoryHabits.isEmpty) return Container();

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 150),
      child: Column(
        children: [
          HabitCategoryTitle(category: widget.category),
          for (final habit in categoryHabits)
            HabitWidget(habit: habit, editable: false),
        ],
      ),
    );
  }
}
