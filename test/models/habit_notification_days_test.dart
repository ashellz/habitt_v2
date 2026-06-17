import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/habit_notification_time.dart';

import '../fixtures/habit_factory.dart';

void main() {
  group('HabitNotificationTime.days', () {
    test('defaults to empty (follow schedule) and fires every weekday', () {
      final slot = HabitNotificationTime(id: 1, minutesOfDay: 8 * 60);
      expect(slot.days, isEmpty);
      for (var weekday = 1; weekday <= 7; weekday++) {
        expect(slot.firesOnWeekday(weekday), isTrue);
      }
    });

    test('restricted set fires only on its weekdays', () {
      final slot = HabitNotificationTime(
        id: 1,
        minutesOfDay: 7 * 60,
        days: [1, 2, 3, 4, 5], // Mon–Fri
      );
      expect(slot.firesOnWeekday(1), isTrue);
      expect(slot.firesOnWeekday(5), isTrue);
      expect(slot.firesOnWeekday(6), isFalse); // Sat
      expect(slot.firesOnWeekday(7), isFalse); // Sun
    });

    test('copy preserves days as an independent list', () {
      final slot = HabitNotificationTime(
        id: 1,
        minutesOfDay: 8 * 60,
        days: [6, 7],
      );
      final clone = slot.copy();
      expect(clone.days, [6, 7]);
      clone.days.add(1);
      expect(slot.days, [6, 7], reason: 'original must not be mutated');
    });

    test('legacy serialized reminder (no days) loads as follow-schedule', () {
      // Pre-feature records have no "days" key.
      final slot = HabitNotificationTime.fromMap({
        'id': 42,
        'minutesOfDay': 9 * 60,
      });
      expect(slot.days, isEmpty);
    });

    test('toMap / fromMap round-trips days', () {
      final slot = HabitNotificationTime(
        id: 42,
        minutesOfDay: 9 * 60,
        days: [2, 4],
      );
      final restored = HabitNotificationTime.fromMap(slot.toMap());
      expect(restored.days, [2, 4]);
    });

    test('fromMap drops out-of-range weekday values', () {
      final slot = HabitNotificationTime.fromMap({
        'id': 1,
        'minutesOfDay': 8 * 60,
        'days': [0, 1, 8, 3, 'x'],
      });
      expect(slot.days, [1, 3]);
    });
  });

  group('Habit change detection for day-only edits', () {
    test('a time-equal, days-different edit is detected by updateHabit', () {
      final original = buildTestHabit();
      original.notificationTimes = [
        HabitNotificationTime(id: 100, minutesOfDay: 8 * 60),
      ];
      original.timestamps.remove('notificationTimes');

      final edited = original.copy();
      // Same id + minutes, only the days change.
      edited.notificationTimes = [
        HabitNotificationTime(id: 100, minutesOfDay: 8 * 60, days: [1, 2, 3]),
      ];

      original.updateHabit(edited);

      expect(original.notificationTimes.single.days, [1, 2, 3]);
      expect(
        original.timestamps.containsKey('notificationTimes'),
        isTrue,
        reason: 'day-only edit must stamp notificationTimes so it can sync',
      );
    });

    test('day-only edit wins the merge via its newer timestamp', () {
      final base = DateTime.utc(2026, 1, 1);

      final local = buildTestHabit();
      local.notificationTimes = [
        HabitNotificationTime(id: 100, minutesOfDay: 8 * 60),
      ];
      local.timestamps['notificationTimes'] = base;

      final incoming = local.copy();
      incoming.notificationTimes = [
        HabitNotificationTime(id: 100, minutesOfDay: 8 * 60, days: [6, 7]),
      ];
      incoming.timestamps['notificationTimes'] = base.add(
        const Duration(days: 1),
      );

      final merged = local.merge(
        incoming,
        reference: base.add(const Duration(days: 2)),
      );

      expect(merged.notificationTimes.single.days, [6, 7]);
    });
  });
}
