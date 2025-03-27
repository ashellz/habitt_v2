import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/pages/other_pages/add_habit_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
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
      body: DefaultTextStyle(
        style: TextStyle(color: Color(0xFF212529)),
        child: GradientBackground(
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

    return Column(
      children: [
        for (final category in categoryProvider.categories)
          Padding(
            padding: EdgeInsets.only(top: 12),
            child: HabitCategory(category: category),
          ),
      ],
    );
  }
}

class HabitCategory extends StatelessWidget {
  const HabitCategory({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final categoryHabits =
        habitProvider.habits
            .where((habit) => habit.categoryId == category.id)
            .toList();

    if (categoryHabits.isEmpty) return Container();

    return Padding(
      padding: EdgeInsets.only(top: category.id == 1 ? 0 : 8),
      child: Column(
        children: [
          // Category title
          HabitCategoryTitle(category: category),
          for (final habit in categoryHabits)
            HabitWidget(
              name: habit.name,
              desc: habit.description,
              streak: habit.streak,
              amount: habit.amount,
              duration: habit.duration,
              amountCompleted: habit.amountCompleted,
              durationCompleted: habit.durationCompleted,
              completed: habit.completed,
              editable: false,
              iconPath: habit.iconPath,
            ),
        ],
      ),
    );
  }
}
