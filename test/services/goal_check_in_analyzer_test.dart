import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/goal_check_in_analyzer.dart';

import '../fixtures/goal_history_factory.dart';
import '../fixtures/habit_factory.dart';

GoalSuggestion? _duration(List<GoalDayRecord> days, int goalMinutes,
        {Set<GoalDirection> blocked = const {}}) =>
    GoalCheckInAnalyzer.analyze(
      currentGoal: goalMinutes * 60,
      isDuration: true,
      days: days,
      blocked: blocked,
    );

GoalSuggestion? _amount(List<GoalDayRecord> days, int goal) =>
    GoalCheckInAnalyzer.analyze(currentGoal: goal, isDuration: false, days: days);

void main() {
  group('lower', () {
    final stopsShort = goalHistory(
      minutes([18, 22, 0, 30, 15, 20, 19, 0, 25, 21, 17, 30, 18, 22]),
      goal: 30 * 60,
    );

    test('usually stops short of the goal: lower to the typical value', () {
      final s = _duration(stopsShort, 30)!;
      expect(s.direction, GoalDirection.lower);
      expect(s.suggestedValue, 20 * 60);
      expect(s.daysMet, 2);
      expect(s.daysUsed, 14);
      expect(s.marks.length, 14);
      expect(s.marks[2], GoalDayMark.missed);
      expect(s.marks[3], GoalDayMark.met);
      expect(s.marks[0], GoalDayMark.partial);
    });

    test('repeated lighter days trigger lower even with a fair hit rate', () {
      final days = goalHistory(
        [30, 30, 18, 30, 30, 20, 30, 30, 30, 18, 30, 20, 30, 30],
        goal: 30,
        lighterIndexes: {2, 9, 11},
      );
      final s = _amount(days, 30)!;
      expect(s.direction, GoalDirection.lower);
      // below-goal days 18, 20, 18, 20 → median 19 → step 5 → 15
      expect(s.suggestedValue, 15);
    });

    test('a cooldown blocks the direction', () {
      expect(_duration(stopsShort, 30, blocked: {GoalDirection.lower}), isNull);
    });
  });

  group('raise', () {
    test('regularly goes past the goal: raise to the median', () {
      final days = goalHistory(
        [8, 7, 9, 6, 8, 8, 7, 9, 8, 6, 8, 9, 7, 8],
        goal: 6,
      );
      final s = _amount(days, 6)!;
      expect(s.direction, GoalDirection.raise);
      expect(s.suggestedValue, 8);
      expect(s.daysPastGoal, 9);
    });

    test('meets the goal exactly every day: nothing', () {
      final days = goalHistory(List.filled(14, 6), goal: 6);
      expect(_amount(days, 6), isNull);
    });

    test('capped at 1.5 times the goal', () {
      final days = goalHistory(List.filled(14, 20), goal: 10);
      expect(_amount(days, 10)!.suggestedValue, 15);
    });
  });

  group('no suggestion', () {
    test('all-or-nothing habits', () {
      final days = goalHistory(
        minutes([0, 0, 25, 0, 0, 30, 0, 0, 0, 25, 0, 30, 0, 0]),
        goal: 25 * 60,
      );
      expect(GoalCheckInAnalyzer.isAllOrNothing(days), isTrue);
      expect(_duration(days, 25), isNull);
    });

    test('fewer than 7 days at the current goal', () {
      final days = goalHistory(
        [5, 5, 5, 5, 5, 5, 5, 5, 5, 3, 3, 3, 3, 3],
        goal: 10,
        goalOverrides: {for (var i = 0; i < 9; i++) i: 20},
      );
      expect(_amount(days, 10), isNull);
    });

    test('skipped days do not count', () {
      final days = goalHistory(
        [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
        goal: 10,
        skippedIndexes: {for (var i = 0; i < 8; i++) i},
      );
      expect(_amount(days, 10), isNull, reason: 'only 6 qualifying days');
    });

    test('one bad week after a good one: the recent week must agree', () {
      final days = goalHistory(
        [2, 3, 2, 3, 2, 3, 2, 10, 10, 10, 10, 10, 10, 4],
        goal: 10,
      );
      expect(_amount(days, 10), isNull);
    });
  });

  group('rounding', () {
    test('duration median rounds down to 5 min steps', () {
      expect(GoalSteps.roundDown(23 * 60 + 40, isDuration: true), 20 * 60);
    });

    test('small amounts keep single steps', () {
      expect(GoalSteps.roundDown(7, isDuration: false), 7);
      expect(GoalSteps.roundDown(12, isDuration: false), 10);
      expect(GoalSteps.roundDown(137, isDuration: false), 130);
    });

    test('long durations use 15 min steps', () {
      expect(GoalSteps.roundDown(2 * 3600 + 20 * 60, isDuration: true), 2 * 3600 + 15 * 60);
    });
  });

  group('collect', () {
    test('reads the 14 days before today from day snapshots', () {
      final today = DateTime(2026, 11, 25);
      Day day(int daysAgo, int done, {int dayGoal = 0}) {
        final h = buildTestHabit(amount: 30, amountCompleted: done)
          ..dayGoal = dayGoal
          ..completed = done >= (dayGoal > 0 ? dayGoal : 30);
        return Day(
          date: today.subtract(Duration(days: daysAgo)),
          habits: [h],
          timestamp: null,
        );
      }

      final records = GoalCheckInAnalyzer.collect(
        days: [day(0, 5), day(1, 18, dayGoal: 18), day(2, 30), day(15, 3)],
        habitId: 1,
        today: today,
      );
      expect(records.length, 2, reason: 'today and day 15 are left out');
      expect(records.first.value, 30);
      expect(records.last.lighter, isTrue);
      expect(records.last.goal, 30, reason: 'usual goal, not the lighter one');
    });
  });

  test('supports only required amount and duration habits', () {
    expect(GoalCheckInAnalyzer.supports(buildTestHabit()), isTrue);
    expect(GoalCheckInAnalyzer.supports(buildTestHabit(optional: true)), isFalse);
    expect(
      GoalCheckInAnalyzer.supports(
        buildTestHabit(trackingType: HabitTrackingType.timeOfDay),
      ),
      isFalse,
    );
  });
}
