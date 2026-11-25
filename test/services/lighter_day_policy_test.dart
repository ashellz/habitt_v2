import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/lighter_day_policy.dart';

import '../fixtures/goal_history_factory.dart';
import '../fixtures/habit_factory.dart';

Habit _duration({int goalMin = 25, int doneMin = 0, int streak = 0}) =>
    buildTestHabit(
      trackingType: HabitTrackingType.duration,
      amount: 0,
      duration: goalMin * 60,
      durationCompleted: doneMin * 60,
    )..streak = streak;

LighterDayInput _input(
  Habit habit, {
  List<int> pastMinutes = const [25, 25, 25, 25, 25, 25, 25],
  int goalMin = 25,
  int lighterThisWeek = 0,
  int misses = 0,
  int perfectStreak = 0,
  int perfectMisses = 0,
  int order = 0,
}) => LighterDayInput(
  habit: habit,
  scheduledToday: true,
  recent: goalHistory(minutes(pastMinutes), goal: goalMin * 60),
  lighterDaysThisWeek: lighterThisWeek,
  habitMisses: misses,
  perfectStreak: perfectStreak,
  perfectTailMisses: perfectMisses,
  order: order,
);

void main() {
  group('offered values', () {
    test('partial progress: done value plus two in between', () {
      expect(
        LighterDayPolicy.offeredValues(
          progress: 18 * 60,
          goal: 30 * 60,
          isDuration: true,
        ),
        [18 * 60, 20 * 60, 25 * 60],
      );
    });

    test('no progress: 25%, 40% and 60% on clean steps', () {
      expect(
        LighterDayPolicy.offeredValues(
          progress: 0,
          goal: 25 * 60,
          isDuration: true,
        ),
        [5 * 60, 10 * 60, 15 * 60],
      );
    });

    test('small amounts never offer zero', () {
      expect(
        LighterDayPolicy.offeredValues(progress: 0, goal: 3, isDuration: false),
        [1],
      );
    });
  });

  group('eligibility', () {
    test('missed yesterday is eligible', () {
      final offer = LighterDayPolicy.evaluate(
        _input(_duration(), pastMinutes: [25, 25, 25, 25, 25, 25, 0]),
      )!;
      expect(offer.kind, LighterDayKind.lighter);
      expect(offer.missedYesterday, isTrue);
      expect(offer.values, [5 * 60, 10 * 60, 15 * 60]);
      expect(offer.daysLeft, 2);
    });

    test('doing well is not eligible', () {
      expect(LighterDayPolicy.evaluate(_input(_duration())), isNull);
    });

    test('low hit rate is eligible', () {
      expect(
        LighterDayPolicy.evaluate(
          _input(_duration(), pastMinutes: [10, 25, 10, 10, 25, 10, 25]),
        ),
        isNotNull,
      );
    });

    test('allowance used up is not eligible', () {
      expect(
        LighterDayPolicy.evaluate(
          _input(
            _duration(),
            pastMinutes: [25, 25, 25, 25, 25, 25, 0],
            lighterThisWeek: 2,
          ),
        ),
        isNull,
      );
    });

    test('completed, optional and already lighter habits are not eligible', () {
      final past = [25, 25, 25, 25, 25, 25, 0];
      expect(
        LighterDayPolicy.evaluate(
          _input(_duration()..completed = true, pastMinutes: past),
        ),
        isNull,
      );
      expect(
        LighterDayPolicy.evaluate(
          _input(_duration()..optional = true, pastMinutes: past),
        ),
        isNull,
      );
      expect(
        LighterDayPolicy.evaluate(
          _input(_duration()..dayGoal = 600, pastMinutes: past),
        ),
        isNull,
      );
    });
  });

  group('streak ends tonight', () {
    test('two misses in a row with allowance left: lighter offer', () {
      final offer = LighterDayPolicy.evaluate(
        _input(_duration(streak: 12), misses: 2),
      )!;
      expect(offer.kind, LighterDayKind.lighter);
      expect(offer.streakAtRisk, 12);
      expect(offer.values, [5 * 60, 10 * 60, 15 * 60]);
    });

    test('two misses in a row with allowance used up: save streak', () {
      final offer = LighterDayPolicy.evaluate(
        _input(_duration(streak: 12), misses: 2, lighterThisWeek: 2),
      )!;
      expect(offer.kind, LighterDayKind.saveStreak);
      expect(offer.values, isEmpty);
    });

    test('perfect-days streak at risk counts too', () {
      final offer = LighterDayPolicy.evaluate(
        _input(_duration(), perfectStreak: 20, perfectMisses: 2),
      )!;
      expect(offer.streakAtRisk, 20);
    });

    test('any progress today means the streak is safe tonight', () {
      final offer = LighterDayPolicy.evaluate(
        _input(_duration(doneMin: 5, streak: 12), misses: 2),
      );
      expect(offer?.streakAtRisk, isNull);
    });
  });

  test('priority: streak at risk, missed yesterday, closest, order', () {
    LighterDayOffer offer({
      int? risk,
      bool missed = false,
      int progress = 0,
      int order = 0,
    }) => LighterDayOffer(
      habit: _duration(),
      kind: LighterDayKind.lighter,
      values: const [],
      progress: progress,
      usualGoal: 100,
      isDuration: false,
      daysLeft: 2,
      missedYesterday: missed,
      order: order,
      streakAtRisk: risk,
    );
    final a = offer(progress: 90, order: 0);
    final b = offer(missed: true, order: 1);
    final c = offer(risk: 5, order: 2);
    expect(LighterDayPolicy.pick([a, b, c]), same(c));
    expect(LighterDayPolicy.pick([a, b]), same(b));
    final d = offer(progress: 50, order: 3);
    expect(LighterDayPolicy.pick([d, a]), same(a));
  });

  test('lighter days this week are counted from day snapshots', () {
    final thursday = DateTime(2026, 11, 26);
    Day day(DateTime date, {int dayGoal = 0}) => Day(
      date: date,
      habits: [_duration()..dayGoal = dayGoal],
      timestamp: null,
    );
    final count = LighterDayPolicy.lighterDaysThisWeek(
      days: [
        day(DateTime(2026, 11, 22), dayGoal: 300), // last Sunday
        day(DateTime(2026, 11, 24), dayGoal: 300), // Tuesday
        day(DateTime(2026, 11, 25)),
        day(thursday, dayGoal: 300), // today, not counted here
      ],
      habitId: 1,
      today: thursday,
    );
    expect(count, 1);
  });
}
