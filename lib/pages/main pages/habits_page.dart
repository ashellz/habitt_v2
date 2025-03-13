import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
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
    return Scaffold(
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
    return Column(children: [HabitCategoryTitle(category: category)]);
  }
}

class HabitCategoryTitle extends StatelessWidget {
  const HabitCategoryTitle({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final localizations = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          category.name,
          style: TextStyle(color: colorProvider.mutedTextColor),
        ),
        Text(
          "${category.habits} ${category.habits == 1 ? localizations.habit : localizations.habits}",
          style: TextStyle(color: colorProvider.mutedTextColor),
        ),
      ],
    );
  }
}
