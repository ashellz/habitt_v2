import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:provider/provider.dart';

void checkReorderCategories(BuildContext context, Habit habit) {
  debugPrint(
    'Checking if we should reorder categories based on habit change...',
  );
  // if (habit.optional) return;

  if (categoryStatusChanged(context, habit)) {
    final categoryProvider = context.read<CategoryProvider>();
    // Reorder categories
    debugPrint(
      'Category status changed, reordering categories based on time slot priority...',
    );
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
      habitProvider.todaysHabits
          .where((h) => h.categoryId == mainCategoryId)
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
