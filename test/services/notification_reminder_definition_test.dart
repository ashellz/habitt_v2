import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/services/notification_service.dart';

import '../fixtures/habit_factory.dart';

// What a sync merge compares to decide whether the other device changed a
// habit's reminder definition (and so needs a full forced reminder resync).
void main() {
  final created = DateTime.utc(2026, 10, 1);

  Habit habitWithReminder({int id = 1}) =>
      buildTestHabit(id: id, createdAt: created)
        ..notificationsEnabled = true
        ..notificationTimes = [
          HabitNotificationTime(id: 10, minutesOfDay: 8 * 60),
        ];

  String key(Habit habit) => NotificationService.reminderDefinitionKey(habit);

  Map<int, String> keys(Iterable<Habit> habits) => {
    for (final habit in habits) habit.id: key(habit),
  };

  group('reminderDefinitionKey', () {
    test('identical habits have the same key', () {
      expect(key(habitWithReminder()), key(habitWithReminder()));
    });

    test('day state does not change the key', () {
      final habit = habitWithReminder();
      final before = key(habit);
      habit
        ..completed = true
        ..amountCompleted = 7
        ..timesCompletedThisWeek = 3
        ..timesCompletedThisMonth = 5
        ..streak = 12;
      expect(key(habit), before);
    });

    test('a moved reminder time changes the key', () {
      final habit = habitWithReminder();
      final before = key(habit);
      habit.notificationTimes.first.minutesOfDay = 9 * 60;
      expect(key(habit), isNot(before));
    });

    test('a replaced reminder slot changes the key', () {
      final habit = habitWithReminder();
      final before = key(habit);
      habit.notificationTimes = [
        HabitNotificationTime(id: 11, minutesOfDay: 8 * 60),
      ];
      expect(key(habit), isNot(before));
    });

    test('removing reminders or turning them off changes the key', () {
      final removed = habitWithReminder()..notificationTimes = [];
      final off = habitWithReminder()..notificationsEnabled = false;
      expect(key(removed), isNot(key(habitWithReminder())));
      expect(key(off), isNot(key(habitWithReminder())));
    });

    test('reminder weekdays change the key', () {
      final habit = habitWithReminder();
      final before = key(habit);
      habit.notificationTimes.first.days = [1, 3];
      expect(key(habit), isNot(before));
    });

    test('reordered slots do not change the key', () {
      final a =
          habitWithReminder()
            ..notificationTimes = [
              HabitNotificationTime(id: 10, minutesOfDay: 8 * 60),
              HabitNotificationTime(id: 11, minutesOfDay: 20 * 60),
            ];
      final b =
          habitWithReminder()
            ..notificationTimes = [
              HabitNotificationTime(id: 11, minutesOfDay: 20 * 60),
              HabitNotificationTime(id: 10, minutesOfDay: 8 * 60),
            ];
      expect(key(a), key(b));
    });

    test('pausing changes the key', () {
      final habit = habitWithReminder();
      final before = key(habit);
      habit.isPaused = true;
      expect(key(habit), isNot(before));
    });

    test('schedule edits change the key', () {
      final base = key(habitWithReminder());
      expect(
        key(habitWithReminder()..scheduleType = ScheduleType.weekly),
        isNot(base),
      );
      expect(key(habitWithReminder()..selectedDaysAWeek = [1, 5]), isNot(base));
      expect(key(habitWithReminder()..weeklyTarget = 4), isNot(base));
    });

    test('alarm, sound and name edits change the key', () {
      final base = key(habitWithReminder());
      expect(key(habitWithReminder()..isAlarm = true), isNot(base));
      expect(key(habitWithReminder()..soundKey = 'chime'), isNot(base));
      expect(key(habitWithReminder()..name = 'Read'), isNot(base));
    });

    test('deleting changes the key, later edits to a deleted habit do not', () {
      final habit = habitWithReminder();
      final before = key(habit);
      habit.isDeleted = true;
      final deleted = key(habit);
      expect(deleted, isNot(before));

      habit.notificationTimes.first.minutesOfDay = 9 * 60;
      expect(key(habit), deleted);
    });
  });

  group('reminderDefinitionsChanged', () {
    test('no change when every habit keeps its key', () {
      final habits = [habitWithReminder(id: 1), habitWithReminder(id: 2)];
      expect(
        NotificationService.reminderDefinitionsChanged(
          keys(habits),
          keys(habits),
        ),
        isFalse,
      );
    });

    test('a habit new on this device is a change', () {
      final before = keys([habitWithReminder(id: 1)]);
      final after = keys([habitWithReminder(id: 1), habitWithReminder(id: 2)]);
      expect(
        NotificationService.reminderDefinitionsChanged(before, after),
        isTrue,
      );
    });

    test('a habit gone from this device is a change', () {
      final before = keys([habitWithReminder(id: 1), habitWithReminder(id: 2)]);
      final after = keys([habitWithReminder(id: 1)]);
      expect(
        NotificationService.reminderDefinitionsChanged(before, after),
        isTrue,
      );
    });

    test('a swapped habit with the same count is a change', () {
      final before = keys([habitWithReminder(id: 1)]);
      final after = keys([habitWithReminder(id: 2)]);
      expect(
        NotificationService.reminderDefinitionsChanged(before, after),
        isTrue,
      );
    });

    test('one edited habit is a change', () {
      final before = keys([habitWithReminder(id: 1), habitWithReminder(id: 2)]);
      final edited = habitWithReminder(id: 2)..isPaused = true;
      final after = keys([habitWithReminder(id: 1), edited]);
      expect(
        NotificationService.reminderDefinitionsChanged(before, after),
        isTrue,
      );
    });
  });

  group('through a real merge', () {
    test('an incoming reminder time edit is detected', () {
      final local = habitWithReminder();
      final before = key(local);

      final incoming =
          habitWithReminder()
            ..notificationTimes = [
              HabitNotificationTime(id: 12, minutesOfDay: 18 * 60),
            ]
            ..timestamps['notificationTimes'] = DateTime.now().toUtc();
      local.applyMerge(local.merge(incoming, preserveLocalDayState: true));

      expect(local.notificationTimes.single.id, 12);
      expect(key(local), isNot(before));
    });

    test('an incoming completion alone is not a definition change', () {
      final local = habitWithReminder();
      final before = key(local);

      final now = DateTime.now().toUtc();
      final incoming =
          habitWithReminder()
            ..completed = true
            ..amountCompleted = 10
            ..timestamps['completed'] = now
            ..timestamps['amountCompleted'] = now;
      local.applyMerge(local.merge(incoming));

      expect(local.completed, isTrue);
      expect(key(local), before);
    });
  });
}
