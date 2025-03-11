import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';

class CategoryProvider extends ChangeNotifier {
  int _selectedCategoryId = 0;

  List<Category> categories = [
    Category(id: 0, name: "All", habits: 4),
    Category(id: 1, name: "Morning", habits: 2),
    Category(id: 2, name: "Afternoon", habits: 3),
    Category(id: 3, name: "Evening", habits: 1),
  ];

  int get selectedCategoryId => _selectedCategoryId;

  void selectCategory(int index) {
    _selectedCategoryId = index;
    notifyListeners();
  }
}
