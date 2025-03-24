import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:provider/provider.dart';

int getCategoryLength(Category category, BuildContext context) {
  final habitProvider = context.watch<HabitProvider>();
  final int categoryHabits =
      habitProvider.habits.where((h) => h.categoryId == category.id).length;
  return categoryHabits;
}
