import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';

class CategoryProvider extends ChangeNotifier {
  int _selectedCategoryId = 0;
  late List<Category> _categories;
  late List<Category> _categoriesOrdered;

  CategoryProvider() {
    _initializeCategories();
  }

  void _initializeCategories() {
    _categories = [
      Category(id: 1, name: "Any time"),
      Category(id: 2, name: "Morning"),
      Category(id: 3, name: "Afternoon"),
      Category(id: 4, name: "Evening"),
    ];
    reorderCategoriesBasedOnTime(); // Initial order
  }

  List<Category> get categories => _categories;
  List<Category> get categoriesOrdered => _categoriesOrdered;

  int get selectedCategoryId => _selectedCategoryId;

  void selectCategory(int index) {
    _selectedCategoryId = index;
    notifyListeners();
  }

  void reorderCategoriesBasedOnTime() {
    final currentHour = DateTime.now().hour;
    final categoriesCopy = List<Category>.from(_categories);

    if (currentHour >= 6 && currentHour < 12) {
      categoriesCopy.insert(0, categoriesCopy.removeAt(1)); // Morning
    } else if (currentHour >= 12 && currentHour < 18) {
      categoriesCopy.insert(0, categoriesCopy.removeAt(2)); // Afternoon
    } else {
      categoriesCopy.insert(0, categoriesCopy.removeAt(3)); // Evening
    }

    _categoriesOrdered = categoriesCopy;
    notifyListeners();
  }
}
