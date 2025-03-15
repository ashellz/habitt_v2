import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';

class CategoryProvider extends ChangeNotifier {
  int _selectedCategoryId = 0;

  List<Category> categories = [
    Category(id: 1, name: "Any time"),
    Category(id: 2, name: "Morning"),
    Category(id: 3, name: "Afternoon"),
    Category(id: 4, name: "Evening"),
  ];

  int get selectedCategoryId => _selectedCategoryId;

  void selectCategory(int index) {
    _selectedCategoryId = index;
    notifyListeners();
  }
}
