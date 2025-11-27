import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:provider/provider.dart';

Category getCategoryById(int id, BuildContext context) {
  final categoryProvider = context.read<CategoryProvider>();
  return categoryProvider.categories.firstWhere((c) => c.id == id);
}
