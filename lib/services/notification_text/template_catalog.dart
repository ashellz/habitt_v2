import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/util/get_duration_string.dart';

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
        return _pickTemplateVariant(l.notificationFallbackGeneric);
      case NotificationTemplateKey.fallbackTitle:
        return _pickTemplateVariant(l.notificationFallbackTitle);
      case NotificationTemplateKey.optional:
        return _pickTemplateVariant(l.notificationOptional);
      case NotificationTemplateKey.freshnessBrandNew:
        return _pickTemplateVariant(l.notificationFreshnessBrandNew);
      case NotificationTemplateKey.freshnessNewDays:
        return _pickTemplateVariant(l.notificationFreshnessNewDays(a['days']!));
      case NotificationTemplateKey.freshnessEstablishedDays:
        return _pickTemplateVariant(
          l.notificationFreshnessEstablishedDays(a['days']!),
        );
      case NotificationTemplateKey.progressNotStartedAmount:
        return _pickTemplateVariant(
          l.notificationProgressNotStartedAmount(a['label']!),
        );
      case NotificationTemplateKey.progressCompletedAmount:
        return _pickTemplateVariant(
          l.notificationProgressCompletedAmount(a['completed']!, a['label']!),
        );
      case NotificationTemplateKey.progressAlmostDoneAmount:
        return _pickTemplateVariant(
          l.notificationProgressAlmostDoneAmount(a['label']!, a['remaining']!),
        );
      case NotificationTemplateKey.progressInProgressAmount:
        return _pickTemplateVariant(
          l.notificationProgressInProgressAmount(
            a['completed']!,
            a['label']!,
            a['remaining']!,
            a['target']!,
          ),
        );
      case NotificationTemplateKey.progressNotStartedDuration:
        return _pickTemplateVariant(l.notificationProgressNotStartedDuration);
      case NotificationTemplateKey.progressCompletedDuration:
        final completed = _formatDurationValue(a['completed']!);
        return _pickTemplateVariant(
          l.notificationProgressCompletedDuration(completed),
        );
      case NotificationTemplateKey.progressAlmostDoneDuration:
        final remaining = _formatDurationValue(a['remaining']!);
        return _pickTemplateVariant(
          l.notificationProgressAlmostDoneDuration(remaining),
        );
      case NotificationTemplateKey.progressInProgressDuration:
        final completed = _formatDurationValue(a['completed']!);
        final target = _formatDurationValue(a['target']!);
        return _pickTemplateVariant(
          l.notificationProgressInProgressDuration(completed, target),
        );
      case NotificationTemplateKey.progressNoTracking:
        return _pickTemplateVariant(l.notificationProgressNoTracking);
      case NotificationTemplateKey.scheduleDaily:
        return _pickTemplateVariant(l.notificationScheduleDaily);
      case NotificationTemplateKey.scheduleCustomEveryDays:
        return _pickTemplateVariant(
          l.notificationScheduleCustomEveryDays(a['days']!),
        );
      case NotificationTemplateKey.scheduleWeeklyReached:
        return _pickTemplateVariant(
          l.notificationScheduleWeeklyReached(a['completed']!, a['target']!),
        );
      case NotificationTemplateKey.scheduleWeeklyImpossible:
        return _pickTemplateVariant(
          l.notificationScheduleWeeklyImpossible(a['completed']!, a['target']!),
        );
      case NotificationTemplateKey.scheduleWeeklyAtRisk:
        return _pickTemplateVariant(
          l.notificationScheduleWeeklyAtRisk(
            a['completed']!,
            a['remaining']!,
            a['target']!,
          ),
        );
      case NotificationTemplateKey.scheduleWeeklyOneLeft:
        return _pickTemplateVariant(
          l.notificationScheduleWeeklyOneLeft(a['completed']!, a['target']!),
        );
      case NotificationTemplateKey.scheduleWeeklyRemaining:
        return _pickTemplateVariant(
          l.notificationScheduleWeeklyRemaining(a['remaining']!, a['target']!),
        );
      case NotificationTemplateKey.scheduleMonthlyReached:
        return _pickTemplateVariant(
          l.notificationScheduleMonthlyReached(a['completed']!, a['target']!),
        );
      case NotificationTemplateKey.scheduleMonthlyImpossible:
        return _pickTemplateVariant(
          l.notificationScheduleMonthlyImpossible(
            a['completed']!,
            a['target']!,
          ),
        );
      case NotificationTemplateKey.scheduleMonthlyAtRisk:
        return _pickTemplateVariant(
          l.notificationScheduleMonthlyAtRisk(
            a['completed']!,
            a['remaining']!,
            a['target']!,
          ),
        );
      case NotificationTemplateKey.scheduleMonthlyOneLeft:
        return _pickTemplateVariant(
          l.notificationScheduleMonthlyOneLeft(a['completed']!, a['target']!),
        );
      case NotificationTemplateKey.scheduleMonthlyRemaining:
        return _pickTemplateVariant(
          l.notificationScheduleMonthlyRemaining(a['remaining']!, a['target']!),
        );
      case NotificationTemplateKey.amountLabelFocus:
        return _pickTemplateVariant(
          l.notificationAmountLabelFocus(a['label']!, a['target']!),
        );
      case NotificationTemplateKey.premadeGoToBedEarly:
        return _pickTemplateVariant(l.notificationPremadeGoToBedEarly);
      case NotificationTemplateKey.premadeBrushTeeth:
        return _pickTemplateVariant(l.notificationPremadeBrushTeeth);
      case NotificationTemplateKey.premadeSkinCare:
        return _pickTemplateVariant(l.notificationPremadeSkinCare);
      case NotificationTemplateKey.premadeWakeUpEarly:
        return _pickTemplateVariant(l.notificationPremadeWakeUpEarly);
      case NotificationTemplateKey.premadeShower:
        return _pickTemplateVariant(l.notificationPremadeShower);
      case NotificationTemplateKey.premadePraying:
        return _pickTemplateVariant(l.notificationPremadePraying);
      case NotificationTemplateKey.premadeRunning:
        return _pickTemplateVariant(l.notificationPremadeRunning);
      case NotificationTemplateKey.premadeWalk:
        return _pickTemplateVariant(l.notificationPremadeWalk);
      case NotificationTemplateKey.premadeGym:
        return _pickTemplateVariant(l.notificationPremadeGym);
      case NotificationTemplateKey.premadeNutrition:
        return _pickTemplateVariant(l.notificationPremadeNutrition);
      case NotificationTemplateKey.premadeMedications:
        return _pickTemplateVariant(l.notificationPremadeMedications);
      case NotificationTemplateKey.premadeDrinkWater:
        return _pickTemplateVariant(l.notificationPremadeDrinkWater);
      case NotificationTemplateKey.premadeStudying:
        return _pickTemplateVariant(l.notificationPremadeStudying);
      case NotificationTemplateKey.premadeWork:
        return _pickTemplateVariant(l.notificationPremadeWork);
      case NotificationTemplateKey.premadeResearch:
        return _pickTemplateVariant(l.notificationPremadeResearch);
      case NotificationTemplateKey.premadeProductivitySession:
        return _pickTemplateVariant(l.notificationPremadeProductivitySession);
      case NotificationTemplateKey.premadeRead:
        return _pickTemplateVariant(l.notificationPremadeRead);
    }
  }
}

String _pickTemplateVariant(String value) {
  final separated =
      value
          .split('|')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
  if (separated.isEmpty) {
    return value;
  }

  // Chooses one option from pipe-separated variants.
  separated.shuffle();
  return separated.first;
}

String _formatDurationValue(Object raw) {
  var formatted = raw.toString();

  // if raw is string, parse to int
  // if raw is int, use directly
  if (raw is String) {
    final parsed = int.tryParse(raw);
    if (parsed != null) {
      formatted = getDurationString(parsed);
    }
  } else if (raw is int) {
    formatted = getDurationString(raw);
  } else if (raw is double) {
    final totalMinutes = raw.round();
    formatted = getDurationString(totalMinutes);
  } else if (raw is num) {
    final totalMinutes = raw.round();
    formatted = getDurationString(totalMinutes);
  }

  return formatted;
}
