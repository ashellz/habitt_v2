import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/health_workout_type.dart';

/// The amount-label noun for a workout habit tracked by session count (e.g.
/// "3 runs today"), resolved to singular/plural for [amount]. [type] ==
/// `null` means the "Any" workout-type filter.
String healthWorkoutAmountLabel(
  HealthWorkoutType? type,
  int amount,
  AppLocalizations loc,
) {
  final isSingular = amount == 1;
  switch (type) {
    case null:
      return isSingular
          ? loc.healthWorkoutLabelAnySingular
          : loc.healthWorkoutLabelAnyPlural;
    case HealthWorkoutType.walking:
      return isSingular
          ? loc.healthWorkoutLabelWalkingSingular
          : loc.healthWorkoutLabelWalkingPlural;
    case HealthWorkoutType.running:
      return isSingular
          ? loc.healthWorkoutLabelRunningSingular
          : loc.healthWorkoutLabelRunningPlural;
    case HealthWorkoutType.cycling:
      return isSingular
          ? loc.healthWorkoutLabelCyclingSingular
          : loc.healthWorkoutLabelCyclingPlural;
    case HealthWorkoutType.swimming:
      return isSingular
          ? loc.healthWorkoutLabelSwimmingSingular
          : loc.healthWorkoutLabelSwimmingPlural;
    case HealthWorkoutType.hiking:
      return isSingular
          ? loc.healthWorkoutLabelHikingSingular
          : loc.healthWorkoutLabelHikingPlural;
    case HealthWorkoutType.flexibility:
      return isSingular
          ? loc.healthWorkoutLabelFlexibilitySingular
          : loc.healthWorkoutLabelFlexibilityPlural;
    case HealthWorkoutType.dancing:
      return isSingular
          ? loc.healthWorkoutLabelDancingSingular
          : loc.healthWorkoutLabelDancingPlural;
    case HealthWorkoutType.rowing:
      return isSingular
          ? loc.healthWorkoutLabelRowingSingular
          : loc.healthWorkoutLabelRowingPlural;
    case HealthWorkoutType.other:
      return isSingular
          ? loc.healthWorkoutLabelOtherSingular
          : loc.healthWorkoutLabelOtherPlural;
  }
}

/// The amount-label noun for a mindfulness habit tracked by session count,
/// resolved to singular/plural for [amount].
String healthMindfulnessAmountLabel(int amount, AppLocalizations loc) {
  return amount == 1
      ? loc.healthMindfulnessLabelSingular
      : loc.healthMindfulnessLabelPlural;
}
