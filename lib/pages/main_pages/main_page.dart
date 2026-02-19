import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/habits/new_habits.dart';
import 'package:habitt/widgets/main_page/main_page_top_section.dart';
import 'package:provider/provider.dart';

import 'package:habitt/models/category.dart';

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
    this.isFirst = false,
  });

  final Category category;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(category.name, style: TextStyle(color: cp.greyText)),
        if (isFirst)
          Container(
            height: 26,
            width: 43,
            decoration: ShapeDecoration(
              color: cp.disabled,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Center(
              child: Text(
                "Now",
                style: TextStyle(color: cp.text, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}
