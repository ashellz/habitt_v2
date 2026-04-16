import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/premade_habit_type.dart';

class NotificationTemplateToken {
  const NotificationTemplateToken({required this.key, this.args = const {}});

  final NotificationTemplateKey key;
  final Map<String, Object> args;
}

enum NotificationTemplateKey {
  fallbackGeneric,
  fallbackTitle,
  optional,
  freshnessBrandNew,
  freshnessNewDays,
  freshnessEstablishedDays,
  progressNotStartedAmount,
  progressCompletedAmount,
  progressAlmostDoneAmount,
  progressInProgressAmount,
  progressNotStartedDuration,
  progressCompletedDuration,
  progressAlmostDoneDuration,
  progressInProgressDuration,
  progressNoTracking,
  scheduleDaily,
  scheduleCustomEveryDays,
  scheduleWeeklyReached,
  scheduleWeeklyImpossible,
  scheduleWeeklyAtRisk,
  scheduleWeeklyOneLeft,
  scheduleWeeklyRemaining,
  scheduleMonthlyReached,
  scheduleMonthlyImpossible,
  scheduleMonthlyAtRisk,
  scheduleMonthlyOneLeft,
  scheduleMonthlyRemaining,
  amountLabelFocus,
  premadeGoToBedEarly,
  premadeBrushTeeth,
  premadeSkinCare,
  premadeWakeUpEarly,
  premadeShower,
  premadePraying,
  premadeRunning,
  premadeWalk,
  premadeGym,
  premadeNutrition,
  premadeMedications,
  premadeDrinkWater,
  premadeStudying,
  premadeWork,
  premadeResearch,
  premadeProductivitySession,
  premadeRead,
}

class NotificationTemplateCatalog {
  static NotificationTemplateToken premadeToken(PremadeHabitType type) {
    switch (type) {
      case PremadeHabitType.goToBedEarly:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeGoToBedEarly,
        );
      case PremadeHabitType.brushTeeth:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeBrushTeeth,
        );
      case PremadeHabitType.skinCare:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeSkinCare,
        );
      case PremadeHabitType.wakeUpEarly:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeWakeUpEarly,
        );
      case PremadeHabitType.shower:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeShower,
        );
      case PremadeHabitType.praying:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadePraying,
        );
      case PremadeHabitType.running:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeRunning,
        );
      case PremadeHabitType.walk:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeWalk,
        );
      case PremadeHabitType.gym:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeGym,
        );
      case PremadeHabitType.nutrition:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeNutrition,
        );
      case PremadeHabitType.medications:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeMedications,
        );
      case PremadeHabitType.drinkWater:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeDrinkWater,
        );
      case PremadeHabitType.studying:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeStudying,
        );
      case PremadeHabitType.work:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeWork,
        );
      case PremadeHabitType.research:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeResearch,
        );
      case PremadeHabitType.productivitySession:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeProductivitySession,
        );
      case PremadeHabitType.read:
        return const NotificationTemplateToken(
          key: NotificationTemplateKey.premadeRead,
        );
    }
  }

  static String resolve(NotificationTemplateToken token, AppLocalizations l) {
    final a = token.args;
    switch (token.key) {
      case NotificationTemplateKey.fallbackGeneric:
        return l.notificationFallbackGeneric;
      case NotificationTemplateKey.fallbackTitle:
        return l.notificationFallbackTitle;
      case NotificationTemplateKey.optional:
        return l.notificationOptional;
      case NotificationTemplateKey.freshnessBrandNew:
        return l.notificationFreshnessBrandNew;
      case NotificationTemplateKey.freshnessNewDays:
        return l.notificationFreshnessNewDays(a['days']!);
      case NotificationTemplateKey.freshnessEstablishedDays:
        return l.notificationFreshnessEstablishedDays(a['days']!);
      case NotificationTemplateKey.progressNotStartedAmount:
        return l.notificationProgressNotStartedAmount(a['label']!);
      case NotificationTemplateKey.progressCompletedAmount:
        return l.notificationProgressCompletedAmount(
          a['completed']!,
          a['label']!,
        );
      case NotificationTemplateKey.progressAlmostDoneAmount:
        return l.notificationProgressAlmostDoneAmount(
          a['label']!,
          a['remaining']!,
        );
      case NotificationTemplateKey.progressInProgressAmount:
        return l.notificationProgressInProgressAmount(
          a['completed']!,
          a['label']!,
          a['target']!,
        );
      case NotificationTemplateKey.progressNotStartedDuration:
        return l.notificationProgressNotStartedDuration;
      case NotificationTemplateKey.progressCompletedDuration:
        return l.notificationProgressCompletedDuration(a['completed']!);
      case NotificationTemplateKey.progressAlmostDoneDuration:
        return l.notificationProgressAlmostDoneDuration(a['remaining']!);
      case NotificationTemplateKey.progressInProgressDuration:
        return l.notificationProgressInProgressDuration(
          a['completed']!,
          a['target']!,
        );
      case NotificationTemplateKey.progressNoTracking:
        return l.notificationProgressNoTracking;
      case NotificationTemplateKey.scheduleDaily:
        return l.notificationScheduleDaily;
      case NotificationTemplateKey.scheduleCustomEveryDays:
        return l.notificationScheduleCustomEveryDays(a['days']!);
      case NotificationTemplateKey.scheduleWeeklyReached:
        return l.notificationScheduleWeeklyReached(
          a['completed']!,
          a['target']!,
        );
      case NotificationTemplateKey.scheduleWeeklyImpossible:
        return l.notificationScheduleWeeklyImpossible(
          a['completed']!,
          a['remaining']!,
          a['target']!,
        );
      case NotificationTemplateKey.scheduleWeeklyAtRisk:
        return l.notificationScheduleWeeklyAtRisk(
          a['completed']!,
          a['remaining']!,
          a['target']!,
        );
      case NotificationTemplateKey.scheduleWeeklyOneLeft:
        return l.notificationScheduleWeeklyOneLeft(
          a['completed']!,
          a['target']!,
        );
      case NotificationTemplateKey.scheduleWeeklyRemaining:
        return l.notificationScheduleWeeklyRemaining(
          a['remaining']!,
          a['target']!,
        );
      case NotificationTemplateKey.scheduleMonthlyReached:
        return l.notificationScheduleMonthlyReached(
          a['completed']!,
          a['target']!,
        );
      case NotificationTemplateKey.scheduleMonthlyImpossible:
        return l.notificationScheduleMonthlyImpossible(
          a['completed']!,
          a['remaining']!,
          a['target']!,
        );
      case NotificationTemplateKey.scheduleMonthlyAtRisk:
        return l.notificationScheduleMonthlyAtRisk(
          a['completed']!,
          a['remaining']!,
          a['target']!,
        );
      case NotificationTemplateKey.scheduleMonthlyOneLeft:
        return l.notificationScheduleMonthlyOneLeft(
          a['completed']!,
          a['target']!,
        );
      case NotificationTemplateKey.scheduleMonthlyRemaining:
        return l.notificationScheduleMonthlyRemaining(
          a['remaining']!,
          a['target']!,
        );
      case NotificationTemplateKey.amountLabelFocus:
        return l.notificationAmountLabelFocus(a['label']!, a['target']!);
      case NotificationTemplateKey.premadeGoToBedEarly:
        return l.notificationPremadeGoToBedEarly;
      case NotificationTemplateKey.premadeBrushTeeth:
        return l.notificationPremadeBrushTeeth;
      case NotificationTemplateKey.premadeSkinCare:
        return l.notificationPremadeSkinCare;
      case NotificationTemplateKey.premadeWakeUpEarly:
        return l.notificationPremadeWakeUpEarly;
      case NotificationTemplateKey.premadeShower:
        return l.notificationPremadeShower;
      case NotificationTemplateKey.premadePraying:
        return l.notificationPremadePraying;
      case NotificationTemplateKey.premadeRunning:
        return l.notificationPremadeRunning;
      case NotificationTemplateKey.premadeWalk:
        return l.notificationPremadeWalk;
      case NotificationTemplateKey.premadeGym:
        return l.notificationPremadeGym;
      case NotificationTemplateKey.premadeNutrition:
        return l.notificationPremadeNutrition;
      case NotificationTemplateKey.premadeMedications:
        return l.notificationPremadeMedications;
      case NotificationTemplateKey.premadeDrinkWater:
        return l.notificationPremadeDrinkWater;
      case NotificationTemplateKey.premadeStudying:
        return l.notificationPremadeStudying;
      case NotificationTemplateKey.premadeWork:
        return l.notificationPremadeWork;
      case NotificationTemplateKey.premadeResearch:
        return l.notificationPremadeResearch;
      case NotificationTemplateKey.premadeProductivitySession:
        return l.notificationPremadeProductivitySession;
      case NotificationTemplateKey.premadeRead:
        return l.notificationPremadeRead;
    }
  }
}
