import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/schedule_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures/habit_factory.dart';

void main() {
  group('reminderMinutesFor', () {
    test('offsets are exactly the five options of the dialog', () {
      expect(scheduleReminderOffsets, [0, 5, 10, 15, 30]);
    });

    test('0 offset is the schedule time itself', () {
      expect(reminderMinutesFor(8 * 60 + 30, 0), 8 * 60 + 30);
    });

    test('subtracts the offset', () {
      expect(reminderMinutesFor(9 * 60, 5), 8 * 60 + 55);
      expect(reminderMinutesFor(9 * 60, 10), 8 * 60 + 50);
      expect(reminderMinutesFor(9 * 60, 15), 8 * 60 + 45);
      expect(reminderMinutesFor(9 * 60, 30), 8 * 60 + 30);
    });

    test('crosses the hour boundary', () {
      expect(reminderMinutesFor(10 * 60 + 5, 15), 9 * 60 + 50);
    });

    test('midnight edge: wraps to the previous evening', () {
      // 00:10, 15 minutes before
      expect(reminderMinutesFor(10, 15), 23 * 60 + 55);
      expect(reminderMinutesFor(0, 30), 23 * 60 + 30);
      expect(reminderMinutesFor(0, 5), 23 * 60 + 55);
      // exactly reaching midnight is fine
      expect(reminderMinutesFor(15, 15), 0);
      expect(reminderMinutesFor(0, 0), 0);
    });

    test('latest minute of the day stays valid', () {
      expect(reminderMinutesFor(23 * 60 + 59, 0), 23 * 60 + 59);
    });

    test('result always fits HabitNotificationTime', () {
      for (final offset in scheduleReminderOffsets) {
        for (var m = 0; m < 24 * 60; m += 7) {
          final r = reminderMinutesFor(m, offset);
          expect(r, inInclusiveRange(0, 24 * 60 - 1));
        }
      }
    });
  });

  group('StateProvider.replaceHabitNotificationTimes', () {
    late StateProvider sp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sp = StateProvider(await SharedPreferences.getInstance());
    });

    test('replaces existing reminders of a habit with a single one', () {
      final habit = buildTestHabit();
      habit.notificationTimes = [
        HabitNotificationTime(id: 1, minutesOfDay: 7 * 60, days: [1, 2]),
        HabitNotificationTime(id: 2, minutesOfDay: 20 * 60),
      ];
      sp.setNotificationsFromHabit(
        enabled: true,
        notificationTimes: habit.notificationTimes,
      );
      expect(sp.habitNotificationTimes, hasLength(2));

      sp.replaceHabitNotificationTimes(reminderMinutesFor(9 * 60, 10));

      final times = sp.habitNotificationTimes;
      expect(times, hasLength(1));
      expect(times.single.minutesOfDay, 8 * 60 + 50);
      expect(times.single.days, isEmpty, reason: 'follows the habit schedule');
      expect(sp.habitNotificationsEnabled, isTrue);
      // the habit itself is untouched until the sheet saves
      expect(habit.notificationTimes, hasLength(2));
    });

    test('turns reminders on when they were off', () {
      sp.setNotificationsFromHabit(enabled: false, notificationTimes: const []);
      expect(sp.habitNotificationsEnabled, isFalse);

      sp.replaceHabitNotificationTimes(8 * 60);

      expect(sp.habitNotificationsEnabled, isTrue);
      expect(sp.habitNotificationTimes.single.minutesOfDay, 8 * 60);
    });

    test('keeps the alarm flag', () {
      sp.setNotificationsFromHabit(
        enabled: true,
        notificationTimes: const [],
        isAlarm: true,
      );
      sp.replaceHabitNotificationTimes(6 * 60);
      expect(sp.habitIsAlarm, isTrue);
    });
  });
}
