import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:provider/provider.dart';

int getCategoryLength(Category category, BuildContext context) {
  final habitProvider = context.watch<HabitProvider>();
  if (habitProvider.habits.isEmpty) return 0;
  if (category.id == 0) {
    return habitProvider.habits.length;
  }

  final int categoryHabits =
      habitProvider.habits.where((h) => h.categoryId == category.id).length;
  return categoryHabits;
}

int getCompletedHabits(Category category, BuildContext context) {
  final habitProvider = context.watch<HabitProvider>();
  if (habitProvider.habits.isEmpty) return 0;

  if (category.id == 0) {
    return habitProvider.habits.where((h) => h.completed).length;
  }

  final int categoryHabits =
      habitProvider.habits
          .where((h) => h.categoryId == category.id && h.completed)
          .length;
  return categoryHabits;
}

int getNotCompletedHabits(Category category, BuildContext context) {
  final habitProvider = context.watch<HabitProvider>();
  if (habitProvider.habits.isEmpty) return 0;

  if (category.id == 0) {
    return habitProvider.habits.where((h) => !h.completed).length;
  }

  final int categoryHabits =
      habitProvider.habits
          .where((h) => h.categoryId == category.id && !h.completed)
          .length;
  return categoryHabits;
}
