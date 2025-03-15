import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';

class CategoryProvider extends ChangeNotifier {
  int _selectedCategoryId = 0;

  List<Category> categories = [
    Category(id: 1, name: "Any time", habits: 4),
    Category(id: 2, name: "Morning", habits: 2),
    Category(id: 3, name: "Afternoon", habits: 3),
    Category(id: 4, name: "Evening", habits: 1),
  ];

  int get selectedCategoryId => _selectedCategoryId;

  void selectCategory(int index) {
    _selectedCategoryId = index;
    notifyListeners();
  }
}
