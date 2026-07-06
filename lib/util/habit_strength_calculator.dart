import 'dart:math';

class HabitEntry {
  const HabitEntry({
    required this.date,
    required this.goal,
    required this.actual,
  });

  final DateTime date;
  final double goal;
  final double actual;
}

enum HabitStrengthInsight { startSmall, pushHarder, stayConsistent }

class HabitStrengthResult {
  const HabitStrengthResult({
    required this.currentStrength,
    required this.strengthHistory,
    required this.dailyValues,
    required this.recentDropFraction,
    required this.varianceLast30Days,
    required this.overPerformanceDaysLast30,
    required this.actionableInsight,
  });

  final double currentStrength;
  final List<double> strengthHistory;
  final List<double> dailyValues;
  final double recentDropFraction;
  final double varianceLast30Days;
  final int overPerformanceDaysLast30;
  final HabitStrengthInsight actionableInsight;
}

class HabitStrengthCalculator {
  const HabitStrengthCalculator._();

  static const double alpha = 0.1;

  static HabitStrengthResult calculate(
    List<HabitEntry> entries, {
    double initialStrength = 0.0,
  }) {
    if (entries.isEmpty) {
      return const HabitStrengthResult(
        currentStrength: 0,
        strengthHistory: <double>[],
        dailyValues: <double>[],
        recentDropFraction: 0,
        varianceLast30Days: 0,
        overPerformanceDaysLast30: 0,
        actionableInsight: HabitStrengthInsight.stayConsistent,
      );
    }

    final orderedEntries = List<HabitEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final strengthHistory = <double>[];
    final dailyValues = <double>[];

    double strength = initialStrength.clamp(0.0, 1.0);
    int consecutiveMissCount = 0;

    for (final entry in orderedEntries) {
      final value = _dailyValue(goal: entry.goal, actual: entry.actual);
      dailyValues.add(value);

      // EMA update: S_t = S_(t-1) + alpha * (V_t - S_(t-1)).
      strength = strength + alpha * (value - strength);

      if (value == 0.0) {
        consecutiveMissCount += 1;
        if (consecutiveMissCount >= 2) {
          strength *= pow(0.9, consecutiveMissCount).toDouble();
        }
      } else {
        consecutiveMissCount = 0;
      }

      strength = strength.clamp(0.0, 1.0);
      strengthHistory.add(strength);
    }

    final recentDropFraction = _recentDropFraction(strengthHistory);
    final varianceLast30Days = _varianceLast30Days(strengthHistory);
    final overPerformanceDaysLast30 = _overPerformanceDaysLast30(dailyValues);
    final insight = getActionableInsight(
      currentStrength: strengthHistory.last,
      strengthHistory: strengthHistory,
      dailyValues: dailyValues,
      recentDropFraction: recentDropFraction,
      varianceLast30Days: varianceLast30Days,
      overPerformanceDaysLast30: overPerformanceDaysLast30,
    );

    return HabitStrengthResult(
      currentStrength: strengthHistory.last,
      strengthHistory: List<double>.unmodifiable(strengthHistory),
      dailyValues: List<double>.unmodifiable(dailyValues),
      recentDropFraction: recentDropFraction,
      varianceLast30Days: varianceLast30Days,
      overPerformanceDaysLast30: overPerformanceDaysLast30,
      actionableInsight: insight,
    );
  }

  static HabitStrengthInsight getActionableInsight({
    required double currentStrength,
    required List<double> strengthHistory,
    required List<double> dailyValues,
    required double recentDropFraction,
    required double varianceLast30Days,
    required int overPerformanceDaysLast30,
  }) {
    // if strength dropped too much
    if (recentDropFraction > 0.15) {
      final n = dailyValues.length;
      final missedTwiceInARow =
          n >= 2 && dailyValues[n - 1] < 1.0 && dailyValues[n - 2] < 1.0;

      // this is to avoid instant sheet if missed one day, annoying
      if (missedTwiceInARow) {
        return HabitStrengthInsight.startSmall;
      }
    }

    final hasThirtyDays = strengthHistory.length >= 30;
    if (!hasThirtyDays) {
      return HabitStrengthInsight.stayConsistent;
    }

    final recentStrength = strengthHistory.sublist(strengthHistory.length - 30);
    final trend = recentStrength.last - recentStrength.first;

    final isStableHighStrength =
        currentStrength > 0.85 &&
        varianceLast30Days < 0.05 &&
        overPerformanceDaysLast30 > 0 &&
        trend >= 0;

    if (isStableHighStrength) {
      return HabitStrengthInsight.pushHarder;
    }

    return HabitStrengthInsight.stayConsistent;
  }

  static double _dailyValue({required double goal, required double actual}) {
    final safeGoal = goal <= 0 ? 1.0 : goal;
    final safeActual = actual.clamp(0.0, double.infinity);

    if (safeActual == 0) {
      return 0.0;
    }

    if (safeActual > safeGoal) {
      return 1.2;
    }

    if (safeActual >= safeGoal) {
      return 1.0;
    }

    return (safeActual / safeGoal) * 0.8;
  }

  static double _recentDropFraction(List<double> history) {
    if (history.length < 5) {
      return 0;
    }

    final baseline = history[history.length - 5];
    final current = history.last;

    if (baseline <= 0 || current >= baseline) {
      return 0;
    }

    return ((baseline - current) / baseline).clamp(0.0, 1.0);
  }

  static double _varianceLast30Days(List<double> history) {
    if (history.length < 30) {
      return 0;
    }

    final recent = history.sublist(history.length - 30);
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    double sumSquaredDiff = 0;

    for (final value in recent) {
      final diff = value - mean;
      sumSquaredDiff += diff * diff;
    }

    return sumSquaredDiff / recent.length;
  }

  static int _overPerformanceDaysLast30(List<double> dailyValues) {
    if (dailyValues.isEmpty) {
      return 0;
    }

    final recentStart = dailyValues.length > 30 ? dailyValues.length - 30 : 0;
    int count = 0;

    for (int i = recentStart; i < dailyValues.length; i++) {
      if (dailyValues[i] > 1.0) {
        count += 1;
      }
    }

    return count;
  }
}
