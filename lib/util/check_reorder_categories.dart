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
  final habits = habitProvider.habits;
  final mainCategory = categoryProvider.categoriesOrdered.first;

  // After completing the habit we check if it's completed
  // If it's completed then we check if the category is completed
  // If the category is completed and it is the main category then we reorder categories with categoryProvider

  if (habit.completed) {
    final habitsInCategory =
        habits.where((h) => h.categoryId == habit.categoryId).toList();
    return habitsInCategory.every(
      (h) => h.completed && h.categoryId == mainCategory.id,
    );
  }
  // If the habit isn't completed, we still check if the category went from completed to not completed
  // If so, we reorder categories as well
  else {
    // Here we count total habits and completed habits
    // If total habits - completed habits == 1 then the category went from completed to not completed
    final habitsInCategory =
        habits.where((h) => h.categoryId == habit.categoryId).toList();
    final totalHabits = habitsInCategory.length;
    final completedHabits = habitsInCategory.where((h) => h.completed).length;
    return totalHabits - completedHabits == 1;
  }
}
