import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/util/day_merge.dart';

import '../fixtures/habit_factory.dart';

// A day's own timestamp moves on any write to it, so it must never decide a
// merge: one device's later edit of another habit on that day used to make it
// skip the other device's whole copy of the day, dropping a newer completion
// (a Health completion on the iPhone) for good.

List<Habit> _all(List<Habit> habits) => habits;

final _created = DateTime.utc(2026, 1, 1);

Habit _health({
  required bool completed,
  required int amountCompleted,
  DateTime? stamp,
}) {
  final h = buildTestHabit(
    id: 1,
    name: 'Steps',
    amount: 8000,
    amountCompleted: amountCompleted,
    createdAt: _created,
    timestamps:
        stamp == null
            ? null
            : {'completed': stamp, 'amountCompleted': stamp},
  );
  h.completed = completed;
  return h;
}

Habit _water({required bool completed, DateTime? stamp}) {
  final h = buildTestHabit(
    id: 2,
    name: 'Water',
    amount: 5,
    amountCompleted: completed ? 5 : 0,
    createdAt: _created,
    timestamps:
        stamp == null
            ? null
            : {'completed': stamp, 'amountCompleted': stamp},
  );
  h.completed = completed;
  return h;
}

void main() {
  final now = DateTime.now().toUtc();
  final day = DateTime(now.year, now.month, now.day - 1);
  final dayStart = now.subtract(const Duration(hours: 30));
  final healthWrite = now.subtract(const Duration(hours: 5)); // iPhone, T1
  final otherEdit = now.subtract(const Duration(hours: 4)); // Android, T2

  // iPhone: the Health habit completed by Health sync at T1.
  Day iphoneDay() => Day(
    date: day,
    habits: [
      _health(completed: true, amountCompleted: 9000, stamp: healthWrite),
      _water(completed: false),
    ],
    timestamp: healthWrite,
  );

  // Android: never read Health; water ticked by hand at T2, after T1.
  Day androidDay() => Day(
    date: day,
    habits: [
      _health(completed: false, amountCompleted: 0, stamp: dayStart),
      _water(completed: true, stamp: otherEdit),
    ],
    timestamp: otherEdit,
  );

  Habit byId(Day d, int id) => d.habits.firstWhere((h) => h.id == id);

  test('an older day still brings its newer habit completion', () {
    final merged = mergeDaySnapshot(
      local: androidDay(),
      incoming: iphoneDay(),
      countingForDay: _all,
    );

    expect(merged, isNotNull);
    expect(byId(merged!, 1).completed, isTrue);
    expect(byId(merged, 1).amountCompleted, 9000);
    // the local, newer edit of the other habit stays
    expect(byId(merged, 2).completed, isTrue);
    expect(merged.timestamp, otherEdit);
  });

  test('both devices end up with the same day', () {
    final onAndroid = mergeDaySnapshot(
      local: androidDay(),
      incoming: iphoneDay(),
      countingForDay: _all,
    )!;
    final onIphone = mergeDaySnapshot(
      local: iphoneDay(),
      incoming: androidDay(),
      countingForDay: _all,
    )!;

    expect(sameDayHabits(onAndroid.habits, onIphone.habits), isTrue);
    expect(onAndroid.timestamp, onIphone.timestamp);
  });

  test('a stuck pair with equal day timestamps heals', () {
    // the state the old day-level skip left behind: same day timestamp,
    // different completion
    final iphone = Day(
      date: day,
      habits: iphoneDay().habits,
      timestamp: otherEdit,
    );
    final merged = mergeDaySnapshot(
      local: androidDay(),
      incoming: iphone,
      countingForDay: _all,
    );

    expect(merged, isNotNull);
    expect(byId(merged!, 1).completed, isTrue);
  });

  test('a newer local completion is kept against an older incoming day', () {
    final local = Day(
      date: day,
      habits: [
        _health(completed: false, amountCompleted: 100, stamp: otherEdit),
      ],
      timestamp: otherEdit,
    );
    final incoming = Day(
      date: day,
      habits: [
        _health(completed: true, amountCompleted: 9000, stamp: healthWrite),
      ],
      timestamp: now.subtract(const Duration(hours: 1)),
    );

    final merged = mergeDaySnapshot(
      local: local,
      incoming: incoming,
      countingForDay: _all,
    );

    // the incoming day is newer, but its copy of the habit is older
    expect(merged == null || !byId(merged, 1).completed, isTrue);
  });

  test('a day the merge does not change is not rewritten', () {
    final merged = mergeDaySnapshot(
      local: iphoneDay(),
      incoming: iphoneDay(),
      countingForDay: _all,
    );

    expect(merged, isNull);
  });

  test('a day with no local copy is stored as it came', () {
    final merged = mergeDaySnapshot(
      local: null,
      incoming: iphoneDay(),
      countingForDay: _all,
    );

    expect(merged, isNotNull);
    expect(byId(merged!, 1).completed, isTrue);
    expect(merged.timestamp, healthWrite);
  });

  test('habit order does not count as a change', () {
    final reordered = Day(
      date: day,
      habits: iphoneDay().habits.reversed.toList(),
      timestamp: healthWrite,
    );

    expect(sameDayHabits(iphoneDay().habits, reordered.habits), isTrue);
  });
}
