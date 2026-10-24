import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/category_progress.dart';
import 'package:habitt/providers/habit_provider.dart';

class CategoryProvider extends ChangeNotifier {
  int _selectedCategoryId = 0;
  late List<Category> _categories;
  late List<Category> _categoriesOrdered;

  HabitProvider? _habitProvider;

  CategoryProvider(this._habitProvider) {
    _initializeCategories();
  }

  // Method to be called by the ProxyProvider's update callback
  void updateDependencies(HabitProvider newHabitProvider) {
    if (_habitProvider != newHabitProvider) {
      _habitProvider = newHabitProvider;
      reorderCategoriesBasedOnTime();
      // Logic to run on dependency update
      notifyListeners();
    }
  }

  void _initializeCategories() {
    _categories = [
      Category(id: 1, name: "Any time"),
      Category(id: 2, name: "Morning"),
      Category(id: 3, name: "Afternoon"),
      Category(id: 4, name: "Evening"),
    ];
    _categoriesOrdered = _categories;
  }

  List<Category> get categories => _categories;
  List<Category> get categoriesOrdered => _categoriesOrdered;

  int get selectedCategoryId => _selectedCategoryId;

  void selectCategory(int index) {
    _selectedCategoryId = index;
    notifyListeners();
  }

  void reorderCategoriesBasedOnTime() {
    // Category ids
    const int anytimeCategoryId = 1;
    const int morningCategoryId = 2;
    const int afternoonCategoryId = 3;
    const int eveningCategoryId = 4;

    // Getting all habits from the habitProvider
    final habits = _habitProvider?.todaysHabits;

    // If the provider failed to load, or we have no habits: abort
    if (habits == null || habits.isEmpty) {
      _categoriesOrdered = List<Category>.from(_categories);
      notifyListeners();
      debugPrint("No habits found, using default category order.");
      return;
    }

    debugPrint("Reordering categories based on time");

    // 1. Initializing progress map
    final Map<int, CategoryProgress> progressMap = {};
    for (Category category in _categories) {
      progressMap[category.id] = CategoryProgress(category.name, category.id);
    }

    // 2. Calculate habit counts
    // Optional habits never block a category from being "completed", so they
    // are left out of the counts entirely.
    for (var habit in habits) {
      if (habit.optional) continue;

      // Get the effective category id
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

    CategoryProgress getProgress(int id, String defaultNameIfMissing) {
      return progressMap[id] ?? CategoryProgress(defaultNameIfMissing, id);
    }

    // 3. Determine the main category
    final currentHour = DateTime.now().hour;
    Category? mainDisplayCategory;

    List<int> readinessCheckOrderIds;
    String currentTimeSlotName = "Unknown";

    if (currentHour >= 4 && currentHour < 12) {
      debugPrint("Current hour is between 4 and 12");
      currentTimeSlotName = "Morning";
      readinessCheckOrderIds = [
        morningCategoryId,
        anytimeCategoryId,
        afternoonCategoryId,
        eveningCategoryId,
      ];
    } else if (currentHour >= 12 && currentHour < 19) {
      debugPrint("Current hour is between 12 and 19");
      currentTimeSlotName = "Afternoon";
      readinessCheckOrderIds = [
        afternoonCategoryId,
        morningCategoryId,
        anytimeCategoryId,
        eveningCategoryId,
      ];
    } else {
      debugPrint("Current hour is between 19 and 4");
      currentTimeSlotName = "Evening";
      readinessCheckOrderIds = [
        eveningCategoryId,
        afternoonCategoryId,
        anytimeCategoryId,
        morningCategoryId,
      ];
    }

    // Find the first "ready" category
    for (int catId in readinessCheckOrderIds) {
      // not real cat, it's short of category :p
      // We ensure _categories contains all category IDs in readinessCheckOrderIds, or add orElse to firstWhere
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

      // Applying the main category if it's ready, if it's not we check the next in order
      // Orders are specified in the hour calculation, it's Anytime, Morning, Afternoon, Evening
      // Except that the checking category is placed first

      if (getProgress(catId, catName).isReady) {
        debugPrint("Category $catName with id $catId is ready");
        mainDisplayCategory = _categories.firstWhere((c) => c.id == catId);
        break;
      } else {
        debugPrint("Category $catName with id $catId is not ready");
      }
    }

    // -------

    // Fallback logic if no category was "ready"
    if (mainDisplayCategory == null) {
      debugPrint(
        "No category is 'ready'. Applying fallback logic for $currentTimeSlotName time.",
      );
      // Every category is completed (or empty): "Any time" goes first, so a
      // completed time-slot category is never kept above it.
      mainDisplayCategory = _categories.firstWhere(
        (c) => c.id == anytimeCategoryId,
      );
    }

    // Debugging output for all category states
    progressMap.forEach((id, progress) {
      debugPrint(
        "Category '${progress.name}' (ID: $id): Total=${progress.totalHabits}, Completed=${progress.completedHabits}, HasHabits=${progress.hasHabits}, IsCompleted=${progress.isCompleted}, IsReady=${progress.isReady}",
      );
    });

    // Corrected debug print for mainDisplayCategory
    debugPrint(
      "Main category determined: ${mainDisplayCategory.name} (ID: ${mainDisplayCategory.id})",
    );

    // 4. Reordering categories

    // Creating a copy of the original categories list to avoid modifying it directly
    final categoriesCopy = List<Category>.from(_categories);

    // Getting the index of the main category
    int index = categoriesCopy.indexWhere(
      (c) => c.id == mainDisplayCategory!.id,
    );

    // If nothing is broken, index should be greater than or equal to 0
    if (index != -1) {
      Category itemToMove = categoriesCopy.removeAt(index);
      categoriesCopy.insert(0, itemToMove);
      debugPrint(
        "Reordered: '${itemToMove.name}' is now the main display category.",
      );
    } else {
      // This might happen if mainDisplayCategory.id is somehow not in _categories, which would be an issue.
      debugPrint(
        "Warning: Main category '${mainDisplayCategory.name}' (ID: ${mainDisplayCategory.id}) not found in categoriesCopy for reordering. List remains as is.",
      );
    }

    _categoriesOrdered = categoriesCopy;
    notifyListeners();
  }
}
