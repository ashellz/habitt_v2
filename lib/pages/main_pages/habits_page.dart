import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/pages/other_pages/add_habit_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:habitt/widgets/habits_page/habits_completed/habits_completed_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
            () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => AddHabitPage())),
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

    return Padding(
      padding: EdgeInsets.only(top: category.id == 1 ? 0 : 8),
      child: Column(
        children: [
          // Category title
          HabitCategoryTitle(category: category),
          for (final habit in categoryHabits)
            HabitWidget(name: habit.name, desc: habit.description),
        ],
      ),
    );
  }
}

class HabitWidget extends StatelessWidget {
  const HabitWidget({super.key, required this.name, required this.desc});

  final String name;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    // Main container
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      height: 74,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorProvider.habitColor,
      ),
      // Inside of the container
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side
          Row(
            children: [
              // Icon circle container
              Container(
                width: 50,
                height: 50,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorProvider.iconBackgroundColor,
                ),
                // Icon
                child: Image.asset("assets/images/icons/compass.png"),
              ),
              // Text
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: SizedBox(
                  width:
                      MediaQuery.of(context).size.width -
                      32 - // 32 padding
                      100 - // 100 on the right
                      70, // 70 on the left
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorProvider.textColor,
                        ),
                      ),
                      Text(
                        desc,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorProvider.mutedTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Completion and streak
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 5),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Stack(
                    children: [
                      Image.asset("assets/images/icons/streak.png"),
                      Center(
                        child: Transform.translate(
                          offset: Offset(0, 1.5),
                          child: FittedBox(
                            child: Text(
                              "4",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorProvider.textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Completion
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.6, 0.6],
                    colors: [
                      colorProvider.colorScheme.vividColor,
                      colorProvider.colorScheme.strokeColor,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "6",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorProvider.backgroundColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Divider(height: 5, thickness: 2),
                    ),
                    Text(
                      "10",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorProvider.backgroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HabitCategoryTitle extends StatelessWidget {
  const HabitCategoryTitle({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;
    final int categoryHabits = getCategoryLength(category, context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          category.name,
          style: TextStyle(color: colorProvider.mutedTextColor),
        ),
        Text(
          "$categoryHabits ${categoryHabits == 1 ? localizations.habit : localizations.habits}",
          style: TextStyle(color: colorProvider.mutedTextColor),
        ),
      ],
    );
  }
}
