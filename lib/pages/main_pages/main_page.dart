import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/habits/new_habits.dart';
import 'package:habitt/widgets/main_page/main_page_top_section.dart';
import 'package:provider/provider.dart';

import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: cp.bg,
      body: ListView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MainPageTopSection(),
          ),
          SizedBox(height: 20),
          Container(
            color: cp.habitBg,
            child: Column(
              children: [
                NewCategoriesList(),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 138,
                  ),
                  child: NewHabits(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewHabitCategoryTitle extends StatelessWidget {
  const NewHabitCategoryTitle({
    super.key,
    required this.category,
    required this.countAdditionalTasks,
  });

  final Category category;
  final bool countAdditionalTasks;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    //    final int categoryHabits = getCategoryLength(
    //    category,
    //  context,
    //countAdditionalTasks,
    //);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(category.name, style: TextStyle(color: cp.greyText))],
    );
  }
}
