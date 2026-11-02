import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/date_key.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime _normalize(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    _normalize(date).toIso8601String().split('T').first;

String _key(DateTime d) => _dayKey(d);

/// Custom "every 3 days" habit whose grid is anchored [anchorDaysAgo] days
/// ago, so with anchorDaysAgo = 8 the scheduled days are -8, -5, -2, +1, ...
Habit _customHabit({
  required int anchorDaysAgo,
  bool showIfMissed = true,
  bool completed = false,
}) {
  final today = _normalize(DateTime.now());
  final anchor = addCalendarDays(today, -(anchorDaysAgo));
  return Habit(
    id: 1,
    name: 'omega 3',
    iconPath: '',
    categoryId: 0,
    scheduleType: ScheduleType.custom,
    customIntervalDays: 3,
    showIfMissed: showIfMissed,
    completed: completed,
    createdAt: addCalendarDays(today, -100),
    lastCustomUpdate: anchor,
    customAppearance: [
      for (var i = 0; i < 365; i += 3) _key(addCalendarDays(anchor, i)),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Habit> habitBox;
  late Box<Day> daysBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('show_if_missed_test');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    Hive.registerAdapter(ScheduleTypeAdapter());
    Hive.registerAdapter(PremadeHabitTypeAdapter());
    Hive.registerAdapter(HabitTrackingTypeAdapter());
    Hive.registerAdapter(HabitNotificationTimeAdapter());
    Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
    habitBox = await Hive.openBox<Habit>('habits');
    daysBox = await Hive.openBox<Day>('days');
  });

  setUp(() async {
    final today = _normalize(DateTime.now());
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': _dayKey(today),
      'daySnapshotsSanitized_v1': true,
      'dateJoined': addCalendarDays(today, -400).toIso8601String(),
    });
    await habitBox.clear();
    await daysBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<HabitProvider> createInitializedProvider() async {
    final provider = HabitProvider();
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!provider.isInitialized) {
      if (DateTime.now().isAfter(deadline)) {
        fail('HabitProvider.init did not complete');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return provider;
  }

  final today = _normalize(DateTime.now());

  Future<void> recordDay(DateTime date, Habit habit) async {
    await daysBox.put(
      _dayKey(date),
      Day(date: date, habits: [habit.copy()], timestamp: DateTime.now()),
    );
  }

  group('show if missed (custom interval)', () {
    test('keeps showing after a missed scheduled day', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8);
      await recordDay(
        addCalendarDays(today, -2),
        _customHabit(anchorDaysAgo: 8),
      );

      expect(provider.appearsOnDay(habit, today), isTrue);
    });

    test('toggle off: does not show off-schedule days', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8, showIfMissed: false);

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('stops once completed on the scheduled day', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8);
      await recordDay(
        addCalendarDays(today, -2),
        _customHabit(anchorDaysAgo: 8, completed: true),
      );

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('never carries over to past days (streaks unaffected)', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8);

      expect(
        provider.appearsOnDay(habit, addCalendarDays(today, -1)),
        isFalse,
      );
    });

    test('does not apply to weekly habits', () async {
      final provider = await createInitializedProvider();
      final habit = Habit(
        id: 1,
        name: 'weekly',
        iconPath: '',
        categoryId: 0,
        scheduleType: ScheduleType.weekly,
        selectedDaysAWeek: [addCalendarDays(today, -2).weekday],
        showIfMissed: true,
        createdAt: addCalendarDays(today, -100),
      );

      expect(provider.appearsOnDay(habit, today), isFalse);
    });

    test('late completion restarts the interval from that day', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8);
      await habitBox.add(habit);
      await recordDay(
        addCalendarDays(today, -2),
        _customHabit(anchorDaysAgo: 8),
      );
      expect(provider.appearsOnDay(habit, today), isTrue);

      habit.completed = true;
      await provider.updateHabitInDB(habit);

      expect(
        habit.customAppearance,
        containsAll([
          _key(addCalendarDays(today, -2)), // history kept
          _key(today),
          _key(addCalendarDays(today, 3)),
        ]),
      );
      expect(
        habit.customAppearance.contains(_key(addCalendarDays(today, 1))),
        isFalse,
      );
    });
  });
  group('show if missed: undo and off-schedule completions', () {
    test('unticking a late completion today undoes the restart', () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 8);
      await habitBox.add(habit);
      await recordDay(
        today.subtract(const Duration(days: 2)),
        _customHabit(anchorDaysAgo: 8),
      );

      habit.completed = true;
      await provider.updateHabitInDB(habit);
      expect(habit.customAppearance, contains(_key(today)));

      habit.completed = false;
      await provider.updateHabitInDB(habit);

      expect(habit.customAppearance, isNot(contains(_key(today))));
      expect(
        habit.customAppearance,
        containsAll([
          _key(today.subtract(const Duration(days: 2))),
          _key(today.add(const Duration(days: 1))), // original grid is back
        ]),
      );
      expect(
        habit.customAppearance,
        isNot(contains(_key(today.add(const Duration(days: 3))))),
      );
      // missed again, so it carries over again
      expect(provider.appearsOnDay(habit, today), isTrue);
    });

    test('an off-schedule completion with nothing missed restarts too',
        () async {
      final provider = await createInitializedProvider();
      // scheduled yesterday (done) and in two days, today is off-schedule
      final habit = _customHabit(anchorDaysAgo: 1);
      await habitBox.add(habit);
      await recordDay(
        today.subtract(const Duration(days: 1)),
        _customHabit(anchorDaysAgo: 1, completed: true),
      );

      habit.completed = true; // e.g. from the habit details page
      await provider.updateHabitInDB(habit);

      expect(
        habit.customAppearance,
        containsAll([
          _key(today.subtract(const Duration(days: 1))), // history kept
          _key(today),
          _key(today.add(const Duration(days: 3))),
        ]),
      );
      expect(
        habit.customAppearance,
        isNot(contains(_key(today.add(const Duration(days: 2))))),
      );
    });

    test('without "show if missed" an off-schedule completion keeps the grid',
        () async {
      final provider = await createInitializedProvider();
      final habit = _customHabit(anchorDaysAgo: 1, showIfMissed: false);
      await habitBox.add(habit);

      habit.completed = true;
      await provider.updateHabitInDB(habit);

      expect(habit.customAppearance, isNot(contains(_key(today))));
      expect(
        habit.customAppearance,
        contains(_key(today.add(const Duration(days: 2)))),
      );
    });
  });

  // Habit "every 3 days" anchored 8 days ago: scheduled -8, -5, -2, +1. The
  // habit is in the box before the provider starts, like in the app, so the
  // provider's live list and the auto-created day snapshots include it.
  group('show if missed: past days and "Other habits"', () {
    Future<(HabitProvider, Habit)> providerWithHabit() async {
      final habit = _customHabit(anchorDaysAgo: 8);
      await habitBox.add(habit);
      final provider = await createInitializedProvider();
      return (provider, provider.habits.firstWhere((h) => h.id == habit.id));
    }

    DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);

    test('missed carry-over days are not streak misses', () async {
      final (provider, live) = await providerWithHabit();
      final done = _customHabit(anchorDaysAgo: 8, completed: true);
      await recordDay(daysAgo(8), done);
      await recordDay(daysAgo(5), done);
      await recordDay(daysAgo(2), _customHabit(anchorDaysAgo: 8)); // missed
      // yesterday it carried over and was left unticked
      await recordDay(daysAgo(1), _customHabit(anchorDaysAgo: 8));

      await provider.assignStreaks(live.id);

      expect(live.streak, 2);
      // only the scheduled day counts as a miss, not the carry-over day
      expect(provider.consecutiveMissesFor(live.id), 1);
    });

    test('a past carry-over day lists the habit under Other habits', () async {
      final (provider, live) = await providerWithHabit();

      final otherYesterday = provider.otherHabitsForDay(daysAgo(1));
      expect(otherYesterday.map((h) => h.id), contains(live.id));
      // scheduled that day, so it's in the regular list instead
      expect(
        provider.otherHabitsForDay(daysAgo(2)).map((h) => h.id),
        isNot(contains(live.id)),
      );
      // none for today, off-schedule habits are done from their details page
      expect(provider.otherHabitsForDay(today), isEmpty);
    });

    test('logging it late on a past day restarts the interval from that day',
        () async {
      final (provider, live) = await providerWithHabit();

      final other = provider
          .otherHabitsForDay(daysAgo(1))
          .firstWhere((h) => h.id == live.id);
      other.completed = true;
      await provider.updateHabitInDB(other, day: daysAgo(1));

      expect(
        live.customAppearance,
        containsAll([
          _key(daysAgo(2)), // history kept
          _key(daysAgo(1)),
          _key(today.add(const Duration(days: 2))),
        ]),
      );
      expect(
        live.customAppearance,
        isNot(contains(_key(today.add(const Duration(days: 1))))),
      );
      // done yesterday, next one is in two days
      expect(provider.appearsOnDay(live, today), isFalse);

      // saved into yesterday, with the schedule it had then
      final recorded = daysBox
          .get(_key(daysAgo(1)))!
          .habits
          .firstWhere((h) => h.id == live.id);
      expect(recorded.completed, isTrue);
      expect(recorded.customAppearance, isNot(contains(_key(daysAgo(1)))));
      expect(
        provider.getHabitsFromDay(daysAgo(1)).map((h) => h.id),
        contains(live.id),
      );
      expect(provider.otherHabitsForDay(daysAgo(1)), isEmpty);
    });

    test('unticking it on that past day undoes the restart', () async {
      final (provider, live) = await providerWithHabit();

      final other = provider
          .otherHabitsForDay(daysAgo(1))
          .firstWhere((h) => h.id == live.id);
      other.completed = true;
      await provider.updateHabitInDB(other, day: daysAgo(1));
      other.completed = false;
      await provider.updateHabitInDB(other, day: daysAgo(1));

      expect(live.customAppearance, isNot(contains(_key(daysAgo(1)))));
      expect(
        live.customAppearance,
        contains(_key(today.add(const Duration(days: 1)))),
      );
      expect(provider.appearsOnDay(live, today), isTrue); // carries over again
      expect(
        provider.otherHabitsForDay(daysAgo(1)).map((h) => h.id),
        contains(live.id),
      );
    });
  });
}
