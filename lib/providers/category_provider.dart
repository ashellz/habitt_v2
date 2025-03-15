import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';

class CategoryProvider extends ChangeNotifier {
  int _selectedCategoryId = 0;

  List<Category> categories = [
    Category(id: 1, name: "Any time", habits: 0),
    Category(id: 2, name: "Morning", habits: 0),
    Category(id: 3, name: "Afternoon", habits: 0),
    Category(id: 4, name: "Evening", habits: 0),
  ];

  CategoryProvider(this.habitProvider) {
    _updateCategories();
  }

  final HabitProvider habitProvider;
  List<Habit> get habits => habitProvider.habits;

  void _updateCategories() {
    for (Habit habit in habits) {
      switch (habit.category) {
        case "Any time":
          categories[0].habits++;
          break;
        case "Morning":
          categories[1].habits++;
          break;
        case "Afternoon":
          categories[2].habits++;
          break;
        case "Evening":
          categories[3].habits++;
          break;
      }
    }
    notifyListeners();
  }

  int get selectedCategoryId => _selectedCategoryId;

  void selectCategory(int index) {
    _selectedCategoryId = index;
    notifyListeners();
  }
}
