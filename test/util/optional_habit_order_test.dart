import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/util/optional_habit_order.dart';

Habit _habit(int id, int categoryId, {int order = 0, int optionalOrder = 0}) {
  return Habit(
    id: id,
    name: 'h$id',
    iconPath: '',
    categoryId: categoryId,
    order: order,
    optionalOrder: optionalOrder,
    optional: true,
  );
}

void main() {
  final categories = [Category(id: 1, name: 'a'), Category(id: 2, name: 'b')];

  List<int> ids(List<Habit> habits) => habits.map((h) => h.id).toList();

  test('unordered habits follow category then in-category order', () {
    final sorted = sortOptionalHabits([
      _habit(1, 2, order: 1),
      _habit(2, 1, order: 2),
      _habit(3, 1, order: 1),
    ], categories);

    expect(ids(sorted), [3, 2, 1]);
  });

  test('optionalOrder ignores categories and comes before unordered', () {
    final sorted = sortOptionalHabits([
      _habit(1, 1, order: 1, optionalOrder: 3),
      _habit(2, 2, order: 1, optionalOrder: 1),
      _habit(3, 1, order: 2, optionalOrder: 2),
      _habit(4, 1, order: 3),
    ], categories);

    expect(ids(sorted), [2, 3, 1, 4]);
  });
}
