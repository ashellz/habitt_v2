import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:provider/provider.dart';

void checkReorderCategories(BuildContext context, Habit habit) {
  if (habit.optional) return;

  if (categoryStatusChanged(context, habit)) {
    final categoryProvider = context.read<CategoryProvider>();
    // Reorder categories
    categoryProvider.reorderCategoriesBasedOnTime();
  }
}

bool categoryStatusChanged(BuildContext context, Habit habit) {
  final habitProvider = Provider.of<HabitProvider>(context, listen: false);
  final categoryProvider = Provider.of<CategoryProvider>(
    context,
    listen: false,
  );
  final orderedCategories = categoryProvider.categoriesOrdered;

  if (orderedCategories.isEmpty) {
    return false;
  }

  final mainCategoryId = orderedCategories.first.id;

  final habitsInMainCategory =
      habitProvider.habits
          .where((h) => h.categoryId == mainCategoryId && !h.optional)
          .toList();

  if (habitsInMainCategory.isEmpty) {
    return false;
  }

  final allMainCategoryCompleted = habitsInMainCategory.every(
    (h) => h.completed,
  );

  // Reorder whenever the main category completion state can affect priority:
  // 1) Completing a habit that makes the main category fully completed.
  // 2) Un-completing any non-optional habit (that category may become ready and
  //    should be allowed to move to main based on time-slot priority).
  if (habit.completed) {
    return habit.categoryId == mainCategoryId && allMainCategoryCompleted;
  }

  return true;
}
