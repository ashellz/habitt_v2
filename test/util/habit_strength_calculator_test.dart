import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/habit_strength_calculator.dart';

/// Calls [HabitStrengthCalculator.getActionableInsight] with sensible defaults,
/// overriding only the fields relevant to the lower-target (startSmall) gate.
///
/// The startSmall branch only depends on [recentDropFraction] and the tail of
/// [dailyValues]; the other parameters are kept in a "not pushHarder" state so a
/// gate failure falls through to `stayConsistent`.
HabitStrengthInsight _insightFor({
  required double recentDropFraction,
  required List<double> dailyValues,
  List<double>? strengthHistory,
}) {
  final history = strengthHistory ?? dailyValues;
  return HabitStrengthCalculator.getActionableInsight(
    currentStrength: history.isEmpty ? 0 : history.last,
    strengthHistory: history,
    dailyValues: dailyValues,
    recentDropFraction: recentDropFraction,
    varianceLast30Days: 0,
    overPerformanceDaysLast30: 0,
  );
}

void main() {
  group('getActionableInsight — lower-target grace gate', () {
    test('single most-recent lapse with a qualifying drop is NOT startSmall',
        () {
      // Last day missed, but the day before was completed → only one lapse.
      final insight = _insightFor(
        recentDropFraction: 0.30,
        dailyValues: const [1.0, 1.0, 1.0, 1.0, 0.0],
      );
      expect(insight, isNot(HabitStrengthInsight.startSmall));
    });

    test('two consecutive not-completed days with a qualifying drop is startSmall',
        () {
      final insight = _insightFor(
        recentDropFraction: 0.30,
        dailyValues: const [1.0, 1.0, 1.0, 0.0, 0.0],
      );
      expect(insight, HabitStrengthInsight.startSmall);
    });

    test('two consecutive lapses without a qualifying drop is NOT startSmall',
        () {
      // Both recent days not completed, but the drop is under the 0.15 threshold.
      final insight = _insightFor(
        recentDropFraction: 0.10,
        dailyValues: const [1.0, 1.0, 1.0, 0.0, 0.0],
      );
      expect(insight, isNot(HabitStrengthInsight.startSmall));
    });

    test('fewer than two entries is NOT startSmall even with a big drop', () {
      final insight = _insightFor(
        recentDropFraction: 0.50,
        dailyValues: const [0.0],
      );
      expect(insight, isNot(HabitStrengthInsight.startSmall));
    });

    test('partial under-target days (0 < value < 1.0) count as not completed',
        () {
      // Neither day reached the target, so both are "not completed".
      final insight = _insightFor(
        recentDropFraction: 0.30,
        dailyValues: const [1.0, 1.0, 1.0, 0.6, 0.5],
      );
      expect(insight, HabitStrengthInsight.startSmall);
    });

    test('one partial + one completed most-recent is NOT startSmall', () {
      // Day-before was under target, but the most recent day hit the target.
      final insight = _insightFor(
        recentDropFraction: 0.30,
        dailyValues: const [1.0, 1.0, 1.0, 0.6, 1.0],
      );
      expect(insight, isNot(HabitStrengthInsight.startSmall));
    });
  });
}
