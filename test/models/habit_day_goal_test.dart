import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';

import '../fixtures/habit_factory.dart';

Habit _reading({int done = 18 * 60}) => buildTestHabit(
  name: 'Reading',
  trackingType: HabitTrackingType.duration,
  amount: 0,
  duration: 30 * 60,
  durationCompleted: done,
);

void main() {
  final now = DateTime.utc(2026, 11, 25, 21);

  group('Habit.dayGoal', () {
    test('defaults to none and the usual goal applies', () {
      final habit = _reading();
      expect(habit.dayGoal, 0);
      expect(habit.hasDayGoal, isFalse);
      expect(habit.effectiveDuration, 30 * 60);
    });

    test('lowering to the current progress completes the habit', () {
      final habit = _reading()..setDayGoal(18 * 60);
      expect(habit.completed, isTrue);
      expect(habit.duration, 30 * 60, reason: 'usual goal untouched');
      expect(habit.effectiveDuration, 18 * 60);
      expect(habit.timestamps['dayGoal'], isNotNull);
    });

    test('lowering above the progress completes once it is reached', () {
      final habit = _reading()..setDayGoal(22 * 60);
      expect(habit.completed, isFalse);
      habit.updateHabitDurationCompleted(22 * 60);
      expect(habit.completed, isTrue);
    });

    test('amount habits compare with the lighter amount', () {
      final habit = buildTestHabit(amount: 30, amountCompleted: 10)
        ..setDayGoal(12);
      expect(habit.completed, isFalse);
      habit.updateHabitAmountCompleted(12);
      expect(habit.completed, isTrue);
      expect(habit.effectiveAmount, 12);
      expect(habit.amount, 30);
    });

    test('clearing it un-completes a day that only met the lighter goal', () {
      final habit = _reading()..setDayGoal(18 * 60);
      habit.setDayGoal(0);
      expect(habit.completed, isFalse);
    });

    test('survives copy, forDay, toMap/fromMap and adoptDayState', () {
      final habit = _reading()..setDayGoal(20 * 60);
      expect(habit.copy().dayGoal, 20 * 60);
      expect(habit.forDay().dayGoal, 20 * 60);
      expect(Habit.fromMap(habit.toMap(forDay: true)).dayGoal, 20 * 60);
      final fresh = _reading(done: 0)..adoptDayState(habit);
      expect(fresh.dayGoal, 20 * 60);
      expect(fresh.timestamps['dayGoal'], habit.timestamps['dayGoal']);
    });

    test('an old backup without the key reads as no lighter day', () {
      final map = (_reading()..setDayGoal(20 * 60)).toMap()..remove('dayGoal');
      expect(Habit.fromMap(map).dayGoal, 0);
    });

    test('a new day starts with the usual goal', () {
      final habit = _reading()..setDayGoal(18 * 60);
      expect(habit.copyResetCompletion().dayGoal, 0);
      habit.clearDayProgress();
      expect(habit.dayGoal, 0);
      final other = _reading()..setDayGoal(18 * 60);
      other.clearDayState();
      expect(other.dayGoal, 0);
    });

    test('time-of-day habits ignore it', () {
      final habit = buildTestHabit(
        trackingType: HabitTrackingType.timeOfDay,
        amount: 1320,
      )..dayGoal = 600;
      expect(habit.hasDayGoal, isFalse);
      expect(habit.effectiveAmount, 1320);
    });

    test('merge keeps it with the day-state that wins', () {
      final local =
          _reading()
            ..setDayGoal(18 * 60)
            ..timestamps['dayGoal'] = DateTime.utc(2026, 11, 25, 20);
      final incoming =
          _reading(done: 10 * 60)
            ..timestamps['durationCompleted'] = DateTime.utc(2026, 11, 25, 9);

      final merged = local.merge(incoming, reference: now);
      expect(merged.dayGoal, 18 * 60);
      expect(merged.durationCompleted, 18 * 60);

      final newerIncoming =
          _reading(done: 25 * 60)
            ..timestamps['durationCompleted'] = DateTime.utc(2026, 11, 25, 20, 30);
      final merged2 = local.merge(newerIncoming, reference: now);
      expect(merged2.durationCompleted, 25 * 60);
      expect(merged2.dayGoal, 0, reason: 'the whole day-state tuple moves');
    });

    test('lowering the usual goal to or below it clears it', () {
      final habit = _reading()..setDayGoal(20 * 60);
      final edited = _reading()..duration = 15 * 60;
      habit.updateHabit(edited);
      expect(habit.dayGoal, 0);
      expect(habit.completed, isTrue, reason: '18 min meets the new 15 min goal');
    });
  });
}
