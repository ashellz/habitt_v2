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
    }
  }
}
