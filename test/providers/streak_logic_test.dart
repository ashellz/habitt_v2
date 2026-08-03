import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/stats_provider.dart';

/// Builds a non-optional amount-tracked habit with the given target/progress.
Habit _amountHabit({
  required int id,
  required int amount,
  required int amountCompleted,
  bool completed = false,
}) {
  return Habit(
    id: id,
    name: 'h$id',
    iconPath: '',
    categoryId: 0,
    amount: amount,
    amountCompleted: amountCompleted,
    completed: completed,
    trackingType: HabitTrackingType.amount,
  );
}

void main() {
  group('classifyDayStatus', () {
    test('all required completed → perfect', () {
      final habits = [
        _amountHabit(id: 1, amount: 1, amountCompleted: 1, completed: true),
        _amountHabit(id: 2, amount: 1, amountCompleted: 1, completed: true),
      ];
      expect(classifyDayStatus(habits), DayCompletionStatus.perfect);
    });

    test('every required has some progress (none complete) → partial', () {
      final habits = [
        _amountHabit(id: 1, amount: 10, amountCompleted: 3),
        _amountHabit(id: 2, amount: 10, amountCompleted: 7),
      ];
      expect(classifyDayStatus(habits), DayCompletionStatus.partial);
    });

    test('one required with progress, another with ZERO → miss (the bug)', () {
      // The old logic flagged this "partial" because ANY habit had progress.
      // The correct rule: a single zero-progress required habit makes it a miss.
      final habits = [
        _amountHabit(id: 1, amount: 10, amountCompleted: 5),
        _amountHabit(id: 2, amount: 10, amountCompleted: 0),
      ];
      expect(classifyDayStatus(habits), DayCompletionStatus.miss);
    });

    test('optional habits are ignored', () {
      final optional = _amountHabit(id: 2, amount: 10, amountCompleted: 0)
        ..optional = true;
      final habits = [
        _amountHabit(id: 1, amount: 1, amountCompleted: 1, completed: true),
        optional,
      ];
      expect(classifyDayStatus(habits), DayCompletionStatus.perfect);
    });

    test('no required habits → none', () {
      final optional = _amountHabit(id: 1, amount: 1, amountCompleted: 0)
        ..optional = true;
      expect(classifyDayStatus([optional]), DayCompletionStatus.none);
    });
  });

  group('computeCurrentStreak', () {
    const perfect = DayCompletionStatus.perfect;
    const miss = DayCompletionStatus.miss;
    const partial = DayCompletionStatus.partial;
    const none = DayCompletionStatus.none;

    test('counts only perfect days in the ongoing run', () {
      // oldest → newest
      expect(computeCurrentStreak([perfect, perfect, perfect]).streak, 3);
    });

    test('tolerates up to 2 misses, breaks on the 3rd', () {
      // newest-side: p, miss, miss, p  → both perfects count (1 miss gap), =2
      expect(computeCurrentStreak([perfect, miss, miss, perfect]).streak, 2);
      // 3 consecutive misses before the older perfect breaks the run
      expect(
        computeCurrentStreak([perfect, miss, miss, miss, perfect]).streak,
        1, // only the most-recent perfect; older one is cut off
      );
    });

    test('partial and none are neutral (do not break or count)', () {
      expect(
        computeCurrentStreak([perfect, partial, none, perfect]).streak,
        2,
      );
    });

    test('trailing misses adjacent to today still bridge to the run', () {
      // newest two are misses (e.g. yesterday/day-before), then a perfect run
      expect(computeCurrentStreak([perfect, perfect, miss, miss]).streak, 2);
      // 3 trailing misses break it → 0
      expect(
        computeCurrentStreak([perfect, perfect, miss, miss, miss]).streak,
        0,
      );
    });

    test('regression: a long tolerated chain does NOT balloon', () {
      // Mostly perfect with isolated single misses never reaching 3-in-a-row.
      final statuses = <DayCompletionStatus>[
        perfect, perfect, miss, perfect, perfect, miss, perfect,
      ];
      expect(computeCurrentStreak(statuses).streak, 5);
    });
  });

  group('computeCurrentStreak tailMisses', () {
    const perfect = DayCompletionStatus.perfect;
    const miss = DayCompletionStatus.miss;
    const partial = DayCompletionStatus.partial;
    const none = DayCompletionStatus.none;

    test('most recent day is perfect → no tolerance spent', () {
      expect(computeCurrentStreak([perfect, perfect, perfect]).tailMisses, 0);
    });

    test('one miss since the last perfect day', () {
      expect(computeCurrentStreak([perfect, miss]).tailMisses, 1);
    });

    test('neutral days do not reset the count', () {
      // partial neither increments nor clears spent tolerance
      expect(computeCurrentStreak([perfect, miss, partial, miss]).tailMisses, 2);
      expect(computeCurrentStreak([perfect, miss, none, miss]).tailMisses, 2);
    });

    test('neutral days alone spend nothing', () {
      expect(computeCurrentStreak([perfect, partial, none]).tailMisses, 0);
    });

    test('older perfect days do not lower the count', () {
      // The walk's leftover missesLeft here is 2 (reset by the older perfects),
      // which would wrongly report 0. The tail is what matters: 2.
      final result = computeCurrentStreak([perfect, perfect, miss, miss]);
      expect(result.streak, 2);
      expect(result.tailMisses, 2);
    });

    test('tolerance exhausted → streak gone, all three misses counted', () {
      final result = computeCurrentStreak([perfect, perfect, miss, miss, miss]);
      expect(result.streak, 0);
      expect(result.tailMisses, 3);
    });

    test('misses older than the run do not count toward the tail', () {
      // Tail is clean; the misses sit behind the most recent perfect day.
      final result = computeCurrentStreak([miss, miss, perfect, perfect]);
      expect(result.streak, 2);
      expect(result.tailMisses, 0);
    });

    test('empty history', () {
      final result = computeCurrentStreak([]);
      expect(result.streak, 0);
      expect(result.tailMisses, 0);
    });
  });

  group('computeLongestStreak', () {
    const perfect = DayCompletionStatus.perfect;
    const miss = DayCompletionStatus.miss;
    const partial = DayCompletionStatus.partial;

    test('finds the longest run across history', () {
      final statuses = <DayCompletionStatus>[
        perfect, perfect, // run A = 2
        miss, miss, miss, // break
        perfect, perfect, perfect, partial, perfect, // run B = 4 perfect days
      ];
      expect(computeLongestStreak(statuses), 4);
    });

    test('leading misses before any perfect are ignored', () {
      expect(computeLongestStreak([miss, miss, miss, perfect, perfect]), 2);
    });
  });
}
