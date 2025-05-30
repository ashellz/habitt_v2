import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/providers/habit_provider.dart';

class CategoryProvider extends ChangeNotifier {
  int _selectedCategoryId = 0;
  late List<Category> _categories;
  late List<Category> _categoriesOrdered;

  HabitProvider? _habitProvider;

  CategoryProvider(HabitProvider habitProvider) {
    _habitProvider = habitProvider;
    _initializeCategories();
  }

  void _initializeCategories() {
    _categories = [
      Category(id: 1, name: "Any time"),
      Category(id: 2, name: "Morning"),
      Category(id: 3, name: "Afternoon"),
      Category(id: 4, name: "Evening"),
    ];
    _categoriesOrdered = _categories;
    reorderCategoriesBasedOnTime();
  }

  List<Category> get categories => _categories;
  List<Category> get categoriesOrdered => _categoriesOrdered;

  int get selectedCategoryId => _selectedCategoryId;

  void selectCategory(int index) {
    _selectedCategoryId = index;
    notifyListeners();
  }

  // Assuming your classes are defined:
  // class Category { final int id; final String name; Category({required this.id, required this.name}); }
  // class Habit { final int categoryId; final bool completed; Habit({required this.categoryId, required this.completed}); }
  // Assume _habitProvider, _categories, _categoriesOrdered, notifyListeners are available

  void reorderCategoriesBasedOnTime() {
    // Define these based on your actual Category model and habit.categoryId values
    const int anytimeCategoryId = 1;
    const int morningCategoryId = 2;
    const int afternoonCategoryId = 3;
    const int eveningCategoryId = 4;

    final habits = _habitProvider?.habits;

    if (habits == null || habits.isEmpty) {
      _categoriesOrdered = List<Category>.from(_categories);
      notifyListeners();
      debugPrint("No habits found, using default category order.");
      return;
    }

    debugPrint("Reordering categories based on time (Corrected)");

    // 1. Initialize progress map
    final Map<int, _CategoryProgress> progressMap = {};
    for (Category category in _categories) {
      progressMap[category.id] = _CategoryProgress(category.name, category.id);
    }

    // 2. Calculate habit counts
    for (var habit in habits) {
      int effectiveCategoryId;
      if (habit.categoryId == morningCategoryId) {
        effectiveCategoryId = morningCategoryId;
      } else if (habit.categoryId == afternoonCategoryId) {
        effectiveCategoryId = afternoonCategoryId;
      } else if (habit.categoryId == eveningCategoryId) {
        effectiveCategoryId = eveningCategoryId;
      } else {
        effectiveCategoryId = anytimeCategoryId;
      }

      if (progressMap.containsKey(effectiveCategoryId)) {
        progressMap[effectiveCategoryId]!.totalHabits++;
        if (habit.completed) {
          progressMap[effectiveCategoryId]!.completedHabits++;
        }
      } else {
        debugPrint(
          "Warning: Habit with unmapped categoryId ${habit.categoryId} (effective: $effectiveCategoryId)",
        );
      }
    }

    _CategoryProgress getProgress(int id, String defaultNameIfMissing) {
      return progressMap[id] ?? _CategoryProgress(defaultNameIfMissing, id);
    }

    // 3. Determine the main category
    final currentHour = DateTime.now().hour;
    Category? mainDisplayCategory;

    List<int> readinessCheckOrderIds;
    int currentTimeSlotFallbackId;
    String currentTimeSlotName = "Unknown";

    if (currentHour >= 4 && currentHour < 12) {
      currentTimeSlotName = "Morning";
      currentTimeSlotFallbackId = morningCategoryId;
      readinessCheckOrderIds = [
        morningCategoryId,
        anytimeCategoryId,
        afternoonCategoryId,
        eveningCategoryId,
      ];
    } else if (currentHour >= 12 && currentHour < 19) {
      currentTimeSlotName = "Afternoon";
      currentTimeSlotFallbackId = afternoonCategoryId;
      readinessCheckOrderIds = [
        afternoonCategoryId,
        morningCategoryId,
        anytimeCategoryId,
        eveningCategoryId,
      ];
    } else {
      currentTimeSlotName = "Evening";
      currentTimeSlotFallbackId = eveningCategoryId;
      readinessCheckOrderIds = [
        eveningCategoryId,
        anytimeCategoryId,
        morningCategoryId,
        afternoonCategoryId,
      ];
    }

    // Find the first "ready" category
    for (int catId in readinessCheckOrderIds) {
      // Ensure _categories contains all category IDs in readinessCheckOrderIds, or add orElse to firstWhere
      String catName =
          _categories
              .firstWhere(
                (c) => c.id == catId,
                orElse:
                    () => Category(
                      id: catId,
                      name: "Unknown $catId",
                    ), // Safety for catName
              )
              .name;
      if (getProgress(catId, catName).isReady) {
        mainDisplayCategory = _categories.firstWhere((c) => c.id == catId);
        if (mainDisplayCategory != null) {
          debugPrint(
            "Primary selection: '${mainDisplayCategory.name}' is ready and highest priority.",
          );
          break; // <<< FIX 1: Exit loop once the highest-priority ready category is found
        }
      }
    }

    // Fallback logic if no category was "ready"
    if (mainDisplayCategory == null) {
      debugPrint(
        "No category is 'ready'. Applying fallback logic for $currentTimeSlotName time.",
      );
      // Fallback 1: Current time slot's category, if it has habits
      String fallbackCatName1 =
          _categories
              .firstWhere(
                (c) => c.id == currentTimeSlotFallbackId,
                orElse:
                    () => Category(
                      id: currentTimeSlotFallbackId,
                      name: "Unknown $currentTimeSlotFallbackId",
                    ),
              )
              .name;
      if (getProgress(currentTimeSlotFallbackId, fallbackCatName1).hasHabits) {
        mainDisplayCategory = _categories.firstWhere(
          (c) => c.id == currentTimeSlotFallbackId,
        );
        if (mainDisplayCategory != null) {
          debugPrint(
            "Fallback 1: Using current time slot category '${mainDisplayCategory.name}' as it has habits.",
          );
        }
      }

      // Fallback 2: "Any time" category
      if (mainDisplayCategory == null) {
        // Only if Fallback 1 didn't set it
        mainDisplayCategory = _categories.firstWhere(
          (c) => c.id == anytimeCategoryId,
        );
        if (mainDisplayCategory != null) {
          debugPrint(
            "Fallback 2: Using 'Any time' category '${mainDisplayCategory.name}'.",
          );
        }
      }

      // Fallback 3: Absolute fallback to the first category
      if (mainDisplayCategory == null && _categories.isNotEmpty) {
        // <<< FIX 2: Only if still null
        mainDisplayCategory = _categories.first;
        debugPrint(
          "Fallback 3: Using first available category '${mainDisplayCategory.name}'.",
        );
      }
    }

    // Debugging output for all category states
    progressMap.forEach((id, progress) {
      debugPrint(
        "Category '${progress.name}' (ID: $id): Total=${progress.totalHabits}, Completed=${progress.completedHabits}, HasHabits=${progress.hasHabits}, IsCompleted=${progress.isCompleted}, IsReady=${progress.isReady}",
      );
    });
    // Corrected debug print for mainDisplayCategory (handles null)
    debugPrint(
      "Main category determined: ${mainDisplayCategory?.name ?? 'None'} (ID: ${mainDisplayCategory?.id ?? 'N/A'})",
    );

    // 4. Reorder categories
    final categoriesCopy = List<Category>.from(_categories);

    // <<< FIX 3: Restore the reordering logic
    if (mainDisplayCategory != null) {
      int index = categoriesCopy.indexWhere(
        (c) => c.id == mainDisplayCategory!.id,
      );
      if (index != -1) {
        Category itemToMove = categoriesCopy.removeAt(index);
        categoriesCopy.insert(0, itemToMove);
        debugPrint(
          "Reordered: '${itemToMove.name}' is now the main display category.",
        );
      } else {
        // This might happen if mainDisplayCategory.id is somehow not in _categories, which would be an issue.
        debugPrint(
          "Warning: Main category '${mainDisplayCategory!.name}' (ID: ${mainDisplayCategory!.id}) not found in categoriesCopy for reordering. List remains as is.",
        );
      }
    } else {
      debugPrint(
        "No main display category determined. Category order remains based on original _categories.",
      );
    }

    _categoriesOrdered = categoriesCopy;
    notifyListeners();
  }
}

class _CategoryProgress {
  final String name; // Name of the category (e.g., "Morning")
  final int id; // Unique ID (e.g., morningCategoryId)
  int totalHabits = 0;
  int completedHabits = 0;

  _CategoryProgress(this.name, this.id);

  bool get hasHabits => totalHabits > 0;
  // A category is completed if it has habits and all of them are completed.
  bool get isCompleted => hasHabits && totalHabits == completedHabits;
  // A category is "ready" if it has habits and they are not all completed.
  bool get isReady => hasHabits && !isCompleted;
}
