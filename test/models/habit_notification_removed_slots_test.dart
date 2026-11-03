import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit_notification_time.dart';

void main() {
  group('HabitNotificationTime.removedSlots', () {
    HabitNotificationTime slot(int id, int minutes) =>
        HabitNotificationTime(id: id, minutesOfDay: minutes);

    test('a slot replaced by a new one (new id) is reported as removed', () {
      final previous = [slot(1, 0)];
      final current = [slot(2, 20 * 60)];

      final removed = HabitNotificationTime.removedSlots(previous, current);

      expect(removed.map((s) => s.id), [1]);
    });

    test('a slot that only changed its time keeps its id and is not removed', () {
      final previous = [slot(1, 0)];
      final current = [slot(1, 20 * 60)];

      expect(HabitNotificationTime.removedSlots(previous, current), isEmpty);
    });

    test('only the deleted slots are reported', () {
      final previous = [slot(1, 8 * 60), slot(2, 12 * 60), slot(3, 20 * 60)];
      final current = [slot(2, 12 * 60)];

      final removed = HabitNotificationTime.removedSlots(previous, current);

      expect(removed.map((s) => s.id), [1, 3]);
    });

    test('nothing removed when slots are added', () {
      final previous = [slot(1, 8 * 60)];
      final current = [slot(1, 8 * 60), slot(2, 20 * 60)];

      expect(HabitNotificationTime.removedSlots(previous, current), isEmpty);
    });
  });
}
