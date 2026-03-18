import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:provider/provider.dart';

int getCategoryLength(
  Category category,
  BuildContext context,
  bool countOptionalHabits, [
  DateTime? selectedDay,
]) {
  final habitProvider = context.watch<HabitProvider>();
  final todayHabits = habitProvider.todaysHabits;
  if (todayHabits.isEmpty && selectedDay == null) return 0;
  if (category.id == 0) {
    if (selectedDay != null) {
      return habitProvider.getHabitsForDate(selectedDay).length;
    }
    return todayHabits.length;
  }

  if (selectedDay != null) {
    final List<Habit> dayHabits = habitProvider.getHabitsForDate(selectedDay);
    return dayHabits
        .where(
          (h) =>
              h.categoryId == category.id &&
              (countOptionalHabits ? true : !h.optional),
        )
        .length;
  }

  final int categoryHabits =
      todayHabits
          .where(
            (h) =>
                h.categoryId == category.id &&
                (countOptionalHabits ? true : !h.optional),
          )
          .length;
  return categoryHabits;
}

int getCompletedHabits(Category category, BuildContext context) {
  final habitProvider = context.watch<HabitProvider>();
  if (habitProvider.todaysHabits.isEmpty) return 0;

  if (category.id == 0) {
    return habitProvider.todaysHabits.where((h) => h.completed).length;
  }

  final int categoryHabits =
      habitProvider.todaysHabits
          .where((h) => h.categoryId == category.id && h.completed)
          .length;
  return categoryHabits;
}

int getNotCompletedHabits(Category category, BuildContext context) {
  final habitProvider = context.watch<HabitProvider>();
  if (habitProvider.todaysHabits.isEmpty) return 0;

  if (category.id == 0) {
    return habitProvider.todaysHabits.where((h) => !h.completed).length;
  }

  final int categoryHabits =
      habitProvider.todaysHabits
          .where((h) => h.categoryId == category.id && !h.completed)
          .length;
  return categoryHabits;
}
