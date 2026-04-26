import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/util/habit_strength_calculator.dart';

class HabitStrengthInsightDialogCopy {
  const HabitStrengthInsightDialogCopy({
    required this.title,
    required this.description,
    required this.primaryLabel,
  });

  final String title;
  final String description;
  final String primaryLabel;
}

class HabitStrengthInsightTextService {
  const HabitStrengthInsightTextService._();

  static const Set<PremadeHabitType> _kNoImprovementInsightPremadeTypes = {
    PremadeHabitType.goToBedEarly,
    PremadeHabitType.brushTeeth,
    PremadeHabitType.skinCare,
    PremadeHabitType.wakeUpEarly,
    PremadeHabitType.shower,
    PremadeHabitType.nutrition,
    PremadeHabitType.medications,
    PremadeHabitType.work,
  };

  static const Set<PremadeHabitType> _kNoTargetDecreaseInsightPremadeTypes = {
    PremadeHabitType.goToBedEarly,
    PremadeHabitType.brushTeeth,
    PremadeHabitType.wakeUpEarly,
    PremadeHabitType.medications,
    PremadeHabitType.work,
  };

  static bool shouldSuppressImprovementInsight(Habit habit) {
    final type = habit.premadeHabitType;
    return type != null && _kNoImprovementInsightPremadeTypes.contains(type);
  }

  static bool shouldSuppressTargetDecreaseInsight(Habit habit) {
    final type = habit.premadeHabitType;
    return type != null && _kNoTargetDecreaseInsightPremadeTypes.contains(type);
  }

  static HabitStrengthInsightDialogCopy buildDialogCopy({
    required AppLocalizations localizations,
    required Habit habit,
    required HabitStrengthInsight insight,
    required bool isMotivationOnly,
    required String todayKey,
    required int dropPercent,
    required int strengthPercent,
    String? fromValue,
    String? toValue,
  }) {
    final title =
        isMotivationOnly
            ? localizations.insightStrengthKeepPushingTitle(habit.name)
            : insight == HabitStrengthInsight.startSmall
            ? localizations.insightStrengthLowerTargetTitle(habit.name)
            : localizations.insightStrengthIncreaseTargetTitle(habit.name);

    final description = _buildDescription(
      localizations: localizations,
      habit: habit,
      insight: insight,
      isMotivationOnly: isMotivationOnly,
      todayKey: todayKey,
      dropPercent: dropPercent,
      strengthPercent: strengthPercent,
      fromValue: fromValue,
      toValue: toValue,
    );

    final primaryLabel =
        isMotivationOnly
            ? _gotItLabel(
              localizations: localizations,
              habitId: habit.id,
              todayKey: todayKey,
            )
            : insight == HabitStrengthInsight.startSmall
            ? localizations.insightStrengthApplyDecrease
            : localizations.insightStrengthApplyIncrease;

    return HabitStrengthInsightDialogCopy(
      title: title,
      description: description,
      primaryLabel: primaryLabel,
    );
  }

  static String _buildDescription({
    required AppLocalizations localizations,
    required Habit habit,
    required HabitStrengthInsight insight,
    required bool isMotivationOnly,
    required String todayKey,
    required int dropPercent,
    required int strengthPercent,
    String? fromValue,
    String? toValue,
  }) {
    if (isMotivationOnly) {
      // Type 1 texts are just motivational ones for premade habit type
      final raw = _resolveStartSmallType1Raw(
        localizations,
        habit.premadeHabitType,
      );
      return _pickVariant(
        raw: raw,
        habitId: habit.id,
        todayKey: todayKey,
        salt: 701,
      );
    }

    if (insight == HabitStrengthInsight.startSmall &&
        fromValue != null &&
        toValue != null) {
      // Type 2 texts are for start small insights with concrete recommendation to decrease target
      final raw = _resolveStartSmallType2Raw(
        localizations,
        habit.premadeHabitType,
        dropPercent,
        fromValue,
        toValue,
      );
      return _pickVariant(
        raw: raw,
        habitId: habit.id,
        todayKey: todayKey,
        salt: 907,
      );
    }

    if (fromValue != null && toValue != null) {
      // Strength increase insights with concrete recommendation to increase target
      final raw = _resolveIncreaseRaw(
        localizations,
        habit.premadeHabitType,
        strengthPercent,
        fromValue,
        toValue,
      );
      return _pickVariant(
        raw: raw,
        habitId: habit.id,
        todayKey: todayKey,
        salt: 1117,
      );
    }

    final raw = _resolveStartSmallType1Raw(
      localizations,
      habit.premadeHabitType,
    );
    return _pickVariant(
      raw: raw,
      habitId: habit.id,
      todayKey: todayKey,
      salt: 1319,
    );
  }

  static String _gotItLabel({
    required AppLocalizations localizations,
    required int habitId,
    required String todayKey,
  }) {
    final idx = (habitId ^ todayKey.hashCode).abs();
    final even = idx.isEven;
    final emoji = even ? '💪' : '🚀';
    final text =
        even
            ? localizations.insightStrengthGotItEven
            : localizations.insightStrengthGotItOdd;
    return '$emoji $text';
  }

  static String _pickVariant({
    required String raw,
    required int habitId,
    required String todayKey,
    required int salt,
  }) {
    // Picks one of the text variants
    final variants = raw
        .split('||')
        .map((it) => it.trim())
        .where((it) => it.isNotEmpty)
        .toList(growable: false);

    if (variants.isEmpty) {
      return '';
    }

    final idx = (habitId ^ todayKey.hashCode ^ salt).abs() % variants.length;
    return variants[idx];
  }

  static String _resolveStartSmallType1Raw(
    AppLocalizations l,
    PremadeHabitType? type,
  ) {
    switch (type) {
      case PremadeHabitType.goToBedEarly:
        return l.insightStrengthStartSmallType1GoToBedEarly;
      case PremadeHabitType.brushTeeth:
        return l.insightStrengthStartSmallType1BrushTeeth;
      case PremadeHabitType.skinCare:
        return l.insightStrengthStartSmallType1SkinCare;
      case PremadeHabitType.wakeUpEarly:
        return l.insightStrengthStartSmallType1WakeUpEarly;
      case PremadeHabitType.shower:
        return l.insightStrengthStartSmallType1Shower;
      case PremadeHabitType.praying:
        return l.insightStrengthStartSmallType1Praying;
      case PremadeHabitType.running:
        return l.insightStrengthStartSmallType1Running;
      case PremadeHabitType.walk:
        return l.insightStrengthStartSmallType1Walk;
      case PremadeHabitType.gym:
        return l.insightStrengthStartSmallType1Gym;
      case PremadeHabitType.nutrition:
        return l.insightStrengthStartSmallType1Nutrition;
      case PremadeHabitType.medications:
        return l.insightStrengthStartSmallType1Medications;
      case PremadeHabitType.drinkWater:
        return l.insightStrengthStartSmallType1DrinkWater;
      case PremadeHabitType.studying:
        return l.insightStrengthStartSmallType1Studying;
      case PremadeHabitType.work:
        return l.insightStrengthStartSmallType1Work;
      case PremadeHabitType.research:
        return l.insightStrengthStartSmallType1Research;
      case PremadeHabitType.productivitySession:
        return l.insightStrengthStartSmallType1ProductivitySession;
      case PremadeHabitType.read:
        return l.insightStrengthStartSmallType1Read;
      case null:
        return l.insightStrengthStartSmallType1Generic;
    }
  }

  static String _resolveStartSmallType2Raw(
    AppLocalizations l,
    PremadeHabitType? type,
    int dropPercent,
    String fromValue,
    String toValue,
  ) {
    switch (type) {
      case PremadeHabitType.goToBedEarly:
        return l.insightStrengthStartSmallType2GoToBedEarly(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.brushTeeth:
        return l.insightStrengthStartSmallType2BrushTeeth(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.skinCare:
        return l.insightStrengthStartSmallType2SkinCare(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.wakeUpEarly:
        return l.insightStrengthStartSmallType2WakeUpEarly(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.shower:
        return l.insightStrengthStartSmallType2Shower(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.praying:
        return l.insightStrengthStartSmallType2Praying(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.running:
        return l.insightStrengthStartSmallType2Running(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.walk:
        return l.insightStrengthStartSmallType2Walk(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.gym:
        return l.insightStrengthStartSmallType2Gym(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.nutrition:
        return l.insightStrengthStartSmallType2Nutrition(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.medications:
        return l.insightStrengthStartSmallType2Medications(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.drinkWater:
        return l.insightStrengthStartSmallType2DrinkWater(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.studying:
        return l.insightStrengthStartSmallType2Studying(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.work:
        return l.insightStrengthStartSmallType2Work(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.research:
        return l.insightStrengthStartSmallType2Research(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.productivitySession:
        return l.insightStrengthStartSmallType2ProductivitySession(
          dropPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.read:
        return l.insightStrengthStartSmallType2Read(
          dropPercent,
          fromValue,
          toValue,
        );
      case null:
        return l.insightStrengthStartSmallType2Generic(
          dropPercent,
          fromValue,
          toValue,
        );
    }
  }

  static String _resolveIncreaseRaw(
    AppLocalizations l,
    PremadeHabitType? type,
    int strengthPercent,
    String fromValue,
    String toValue,
  ) {
    switch (type) {
      case PremadeHabitType.goToBedEarly:
        return l.insightStrengthIncreaseGoToBedEarly(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.brushTeeth:
        return l.insightStrengthIncreaseBrushTeeth(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.skinCare:
        return l.insightStrengthIncreaseSkinCare(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.wakeUpEarly:
        return l.insightStrengthIncreaseWakeUpEarly(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.shower:
        return l.insightStrengthIncreaseShower(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.praying:
        return l.insightStrengthIncreasePraying(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.running:
        return l.insightStrengthIncreaseRunning(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.walk:
        return l.insightStrengthIncreaseWalk(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.gym:
        return l.insightStrengthIncreaseGym(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.nutrition:
        return l.insightStrengthIncreaseNutrition(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.medications:
        return l.insightStrengthIncreaseMedications(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.drinkWater:
        return l.insightStrengthIncreaseDrinkWater(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.studying:
        return l.insightStrengthIncreaseStudying(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.work:
        return l.insightStrengthIncreaseWork(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.research:
        return l.insightStrengthIncreaseResearch(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.productivitySession:
        return l.insightStrengthIncreaseProductivitySession(
          strengthPercent,
          fromValue,
          toValue,
        );
      case PremadeHabitType.read:
        return l.insightStrengthIncreaseRead(
          strengthPercent,
          fromValue,
          toValue,
        );
      case null:
        return l.insightStrengthIncreaseGeneric(
          strengthPercent,
          fromValue,
          toValue,
        );
    }
  }
}
