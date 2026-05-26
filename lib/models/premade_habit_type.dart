import 'package:habitt/l10n/app_localizations.dart';

enum PremadeHabitType {
  goToBedEarly,
  brushTeeth,
  skinCare,
  wakeUpEarly,
  shower,
  praying,
  running,
  walk,
  gym,
  nutrition,
  medications,
  drinkWater,
  studying,
  work,
  research,
  productivitySession,
  read,
}

extension PremadeHabitTypeLabel on PremadeHabitType {
  String get label {
    switch (this) {
      case PremadeHabitType.goToBedEarly:
        return 'Go to bed early';
      case PremadeHabitType.brushTeeth:
        return 'Brush teeth';
      case PremadeHabitType.skinCare:
        return 'Skin care';
      case PremadeHabitType.wakeUpEarly:
        return 'Wake up early';
      case PremadeHabitType.shower:
        return 'Shower';
      case PremadeHabitType.praying:
        return 'Praying';
      case PremadeHabitType.running:
        return 'Running';
      case PremadeHabitType.walk:
        return 'Walk';
      case PremadeHabitType.gym:
        return 'Gym';
      case PremadeHabitType.nutrition:
        return 'Nutrition';
      case PremadeHabitType.medications:
        return 'Medications';
      case PremadeHabitType.drinkWater:
        return 'Drink water';
      case PremadeHabitType.studying:
        return 'Studying';
      case PremadeHabitType.work:
        return 'Work';
      case PremadeHabitType.research:
        return 'Research';
      case PremadeHabitType.productivitySession:
        return 'Productivity session';
      case PremadeHabitType.read:
        return 'Read';
    }
  }
}

extension PremadeHabitTypeLocalizedName on PremadeHabitType {
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case PremadeHabitType.goToBedEarly:
        return l10n.premadeHabitGoToBedEarly;
      case PremadeHabitType.brushTeeth:
        return l10n.premadeHabitBrushTeeth;
      case PremadeHabitType.skinCare:
        return l10n.premadeHabitSkinCare;
      case PremadeHabitType.wakeUpEarly:
        return l10n.premadeHabitWakeUpEarly;
      case PremadeHabitType.shower:
        return l10n.premadeHabitShower;
      case PremadeHabitType.praying:
        return l10n.premadeHabitPraying;
      case PremadeHabitType.running:
        return l10n.premadeHabitRunning;
      case PremadeHabitType.walk:
        return l10n.premadeHabitWalk;
      case PremadeHabitType.gym:
        return l10n.premadeHabitGym;
      case PremadeHabitType.nutrition:
        return l10n.premadeHabitNutrition;
      case PremadeHabitType.medications:
        return l10n.premadeHabitMedications;
      case PremadeHabitType.drinkWater:
        return l10n.premadeHabitDrinkWater;
      case PremadeHabitType.studying:
        return l10n.premadeHabitStudying;
      case PremadeHabitType.work:
        return l10n.premadeHabitWork;
      case PremadeHabitType.research:
        return l10n.premadeHabitResearch;
      case PremadeHabitType.productivitySession:
        return l10n.premadeHabitProductivitySession;
      case PremadeHabitType.read:
        return l10n.premadeHabitRead;
    }
  }
}

/// Capitalized camel-case key suffix used to derive ARB key names per type.
///
/// Used by `HabitStrengthInsightTextService` to look up variant lists such as
/// `insightStrengthStartSmallType1GoToBedEarly1`..`5`.
extension PremadeHabitTypeArbSuffix on PremadeHabitType {
  String get arbKeySuffix {
    switch (this) {
      case PremadeHabitType.goToBedEarly:
        return 'GoToBedEarly';
      case PremadeHabitType.brushTeeth:
        return 'BrushTeeth';
      case PremadeHabitType.skinCare:
        return 'SkinCare';
      case PremadeHabitType.wakeUpEarly:
        return 'WakeUpEarly';
      case PremadeHabitType.shower:
        return 'Shower';
      case PremadeHabitType.praying:
        return 'Praying';
      case PremadeHabitType.running:
        return 'Running';
      case PremadeHabitType.walk:
        return 'Walk';
      case PremadeHabitType.gym:
        return 'Gym';
      case PremadeHabitType.nutrition:
        return 'Nutrition';
      case PremadeHabitType.medications:
        return 'Medications';
      case PremadeHabitType.drinkWater:
        return 'DrinkWater';
      case PremadeHabitType.studying:
        return 'Studying';
      case PremadeHabitType.work:
        return 'Work';
      case PremadeHabitType.research:
        return 'Research';
      case PremadeHabitType.productivitySession:
        return 'ProductivitySession';
      case PremadeHabitType.read:
        return 'Read';
    }
  }
}
