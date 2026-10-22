import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';

/// Order of the separate "Optional habits" section.
///
/// Optional habits the user has arranged ([Habit.optionalOrder] > 0) come
/// first in that order. The rest follow by category, then by their order
/// inside the category, so nothing moves until the user reorders them.
List<Habit> sortOptionalHabits(
  Iterable<Habit> habits,
  List<Category> categories,
) {
  final categoryPosition = {
    for (int i = 0; i < categories.length; i++) categories[i].id: i,
  };

  int compare(Habit a, Habit b) {
    final aSet = a.optionalOrder > 0;
    final bSet = b.optionalOrder > 0;
    if (aSet != bSet) return aSet ? -1 : 1;
    if (aSet) {
      final orderCompare = a.optionalOrder.compareTo(b.optionalOrder);
      if (orderCompare != 0) return orderCompare;
      return a.id.compareTo(b.id);
    }

    final categoryCompare = (categoryPosition[a.categoryId] ?? 1 << 30)
        .compareTo(categoryPosition[b.categoryId] ?? 1 << 30);
    if (categoryCompare != 0) return categoryCompare;

    final aOrder = a.order <= 0 ? 1 << 30 : a.order;
    final bOrder = b.order <= 0 ? 1 << 30 : b.order;
    final orderCompare = aOrder.compareTo(bOrder);
    if (orderCompare != 0) return orderCompare;
    return a.id.compareTo(b.id);
  }

  return habits.toList()..sort(compare);
}
