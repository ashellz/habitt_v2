import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/services/habit_strength_insight_text_service.dart';
import 'package:habitt/util/habit_strength_calculator.dart';

import '../fixtures/habit_factory.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('buildDialogCopy is deterministic for same habit/day', () {
    final habit = buildTestHabit(
      id: 22,
      premadeHabitType: PremadeHabitType.gym,
      name: 'Gym',
    );

    final first = HabitStrengthInsightTextService.buildDialogCopy(
      localizations: l10n,
      habit: habit,
      insight: HabitStrengthInsight.startSmall,
      isMotivationOnly: false,
      todayKey: '2026-04-23',
      dropPercent: 24,
      strengthPercent: 88,
      fromValue: '30 min',
      toValue: '24 min',
    );

    final second = HabitStrengthInsightTextService.buildDialogCopy(
      localizations: l10n,
      habit: habit,
      insight: HabitStrengthInsight.startSmall,
      isMotivationOnly: false,
      todayKey: '2026-04-23',
      dropPercent: 24,
      strengthPercent: 88,
      fromValue: '30 min',
      toValue: '24 min',
    );

    expect(first.title, second.title);
    expect(first.description, second.description);
    expect(first.primaryLabel, second.primaryLabel);
  });

  test('startSmall motivation-only uses Type1 messaging', () {
    final habit = buildTestHabit(
      id: 33,
      premadeHabitType: PremadeHabitType.read,
      name: 'Read',
    );

    final copy = HabitStrengthInsightTextService.buildDialogCopy(
      localizations: l10n,
      habit: habit,
      insight: HabitStrengthInsight.startSmall,
      isMotivationOnly: true,
      todayKey: '2026-04-23',
      dropPercent: 31,
      strengthPercent: 80,
    );

    expect(copy.title, l10n.insightStrengthKeepPushingTitle('Read'));
    expect(copy.description, isNot(contains('->')));
    expect(copy.primaryLabel, contains('Got it'));
  });

  test('startSmall with recommendation uses Type2 messaging placeholders', () {
    final habit = buildTestHabit(
      id: 44,
      premadeHabitType: PremadeHabitType.studying,
      name: 'Study',
    );

    final copy = HabitStrengthInsightTextService.buildDialogCopy(
      localizations: l10n,
      habit: habit,
      insight: HabitStrengthInsight.startSmall,
      isMotivationOnly: false,
      todayKey: '2026-04-23',
      dropPercent: 19,
      strengthPercent: 90,
      fromValue: '60 min',
      toValue: '48 min',
    );

    expect(copy.title, l10n.insightStrengthLowerTargetTitle('Study'));
    expect(copy.description, contains('19'));
    expect(copy.description, contains('60 min'));
    expect(copy.description, contains('48 min'));
    expect(copy.primaryLabel, l10n.insightStrengthApplyDecrease);
  });

  test(
    'pushHarder with recommendation uses increase messaging placeholders',
    () {
      final habit = buildTestHabit(
        id: 55,
        premadeHabitType: PremadeHabitType.running,
        name: 'Run',
      );

      final copy = HabitStrengthInsightTextService.buildDialogCopy(
        localizations: l10n,
        habit: habit,
        insight: HabitStrengthInsight.pushHarder,
        isMotivationOnly: false,
        todayKey: '2026-04-23',
        dropPercent: 2,
        strengthPercent: 93,
        fromValue: '5 km',
        toValue: '6 km',
      );

      expect(copy.title, l10n.insightStrengthIncreaseTargetTitle('Run'));
      expect(copy.description, contains('93'));
      expect(copy.description, contains('5 km'));
      expect(copy.description, contains('6 km'));
      expect(copy.primaryLabel, l10n.insightStrengthApplyIncrease);
    },
  );

  test(
    'generic fallback uses generic variant pools when premade type is null',
    () {
      final habit = buildTestHabit(
        id: 66,
        premadeHabitType: null,
        name: 'Custom Habit',
      );

      final copy = HabitStrengthInsightTextService.buildDialogCopy(
        localizations: l10n,
        habit: habit,
        insight: HabitStrengthInsight.startSmall,
        isMotivationOnly: false,
        todayKey: '2026-04-23',
        dropPercent: 26,
        strengthPercent: 86,
        fromValue: '10 reps',
        toValue: '8 reps',
      );

      expect(copy.description, contains('10 reps'));
      expect(copy.description, contains('8 reps'));
    },
  );

  test('shouldSuppressImprovementInsight keeps existing 8-type behavior', () {
    final suppressed = <PremadeHabitType>{
      PremadeHabitType.goToBedEarly,
      PremadeHabitType.brushTeeth,
      PremadeHabitType.skinCare,
      PremadeHabitType.wakeUpEarly,
      PremadeHabitType.shower,
      PremadeHabitType.nutrition,
      PremadeHabitType.medications,
      PremadeHabitType.work,
    };

    for (final type in PremadeHabitType.values) {
      final habit = buildTestHabit(premadeHabitType: type);
      final actual =
          HabitStrengthInsightTextService.shouldSuppressImprovementInsight(
            habit,
          );
      expect(actual, suppressed.contains(type), reason: 'Mismatch for $type');
    }
  });
}
