import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/services/notification_text/composer.dart';
import 'package:habitt/services/notification_text/locale_resolver.dart';
import 'package:habitt/services/notification_text/rules/amount_label_rule.dart';
import 'package:habitt/services/notification_text/rules/freshness_rule.dart';
import 'package:habitt/services/notification_text/rules/optional_rule.dart';
import 'package:habitt/services/notification_text/rules/premade_rule.dart';
import 'package:habitt/services/notification_text/rules/progress_rule.dart';
import 'package:habitt/services/notification_text/rules/schedule_rule.dart';
import 'package:habitt/services/notification_text/template_catalog.dart';
import 'package:habitt/services/notification_text/types.dart';

export 'package:habitt/services/notification_text/types.dart';

class HabitNotificationExamples {
  static Map<PremadeHabitType, String> premadeTypeDescriptions({
    String localeCode = 'en',
  }) {
    final localizations = HabitNotificationLocaleResolver.resolveFromLocaleCode(
      localeCode,
    );
    final result = <PremadeHabitType, String>{};
    for (final type in PremadeHabitType.values) {
      result[type] = NotificationTemplateCatalog.resolve(
        NotificationTemplateCatalog.premadeToken(type),
        localizations,
      );
    }
    return result;
  }

  static const Map<HabitNotificationProgressState, String>
  progressStateDescriptions = {
    HabitNotificationProgressState.noTrackingGoal:
        'Check has no amount/duration goal and should emphasize showing up.',
    HabitNotificationProgressState.notStarted:
        'Check no progress yet and should encourage starting small.',
    HabitNotificationProgressState.inProgress:
        'Check partial progress and nudge toward completion.',
    HabitNotificationProgressState.almostDone:
        'Check near-complete progress and use close-to-finish tone.',
    HabitNotificationProgressState.completed:
        'Check target already completed and suggest bonus consistency.',
  };

  static const Map<HabitNotificationScheduleState, String>
  scheduleStateDescriptions = {
    HabitNotificationScheduleState.daily: 'Daily schedule text.',
    HabitNotificationScheduleState.weeklyOnTrack:
        'Weekly target remains on track.',
    HabitNotificationScheduleState.weeklyLastWindow:
        'Weekly target becomes risky if skipped today.',
    HabitNotificationScheduleState.weeklyGoalReached:
        'Weekly target already reached.',
    HabitNotificationScheduleState.weeklyImpossible:
        'Weekly target mathematically impossible from today onward.',
    HabitNotificationScheduleState.monthlyOnTrack:
        'Monthly target remains on track.',
    HabitNotificationScheduleState.monthlyLastWindow:
        'Monthly target becomes risky if skipped today.',
    HabitNotificationScheduleState.monthlyGoalReached:
        'Monthly target already reached.',
    HabitNotificationScheduleState.monthlyImpossible:
        'Monthly target mathematically impossible from today onward.',
    HabitNotificationScheduleState.custom: 'Custom cadence reminder.',
  };

  static const Map<HabitNotificationFreshnessState, String>
  freshnessStateDescriptions = {
    HabitNotificationFreshnessState.brandNew:
        'Habit started very recently and should get extra encouragement.',
    HabitNotificationFreshnessState.newHabit:
        'Habit is still fresh and should reinforce early consistency.',
    HabitNotificationFreshnessState.established:
        'Habit is established and should reinforce compounding consistency.',
  };
}

class HabitNotificationTextBuilder {
  static HabitNotificationText build(
    HabitNotificationContext context, {
    int maxSegments = 3,
  }) {
    final evaluatedChecks = <String>[];
    final segments = <HabitNotificationSegment>[];

    final premadeSegment = PremadeNotificationRule.evaluate(
      context,
      evaluatedChecks,
    );
    if (premadeSegment != null) {
      segments.add(premadeSegment);
    }

    final progressResult = ProgressNotificationRule.evaluate(
      context,
      evaluatedChecks,
    );
    segments.add(progressResult.segment);

    final scheduleResult = ScheduleNotificationRule.evaluate(
      context,
      evaluatedChecks,
    );
    segments.add(scheduleResult.segment);

    final freshnessResult = FreshnessNotificationRule.evaluate(
      context,
      evaluatedChecks,
    );
    segments.add(freshnessResult.segment);

    final amountLabelSegment = AmountLabelNotificationRule.evaluate(
      context,
      evaluatedChecks,
    );
    if (amountLabelSegment != null) {
      segments.add(amountLabelSegment);
    }

    final optionalSegment = OptionalNotificationRule.evaluate(
      context,
      evaluatedChecks,
    );
    if (optionalSegment != null) {
      segments.add(optionalSegment);
    }

    if (segments.isEmpty) {
      segments.add(
        const HabitNotificationSegment(
          category: HabitNotificationSegmentCategory.fallback,
          priority: 1,
          template: NotificationTemplateToken(
            key: NotificationTemplateKey.fallbackGeneric,
          ),
          debugKey: 'fallback.generic',
        ),
      );
    }

    final selected = HabitNotificationComposer.selectTopSegments(
      segments,
      maxSegments: maxSegments,
    );

    final resolvedSegments = <String>[];
    for (final segment in selected) {
      final text =
          NotificationTemplateCatalog.resolve(
            segment.template,
            context.localizations,
          ).trim();
      if (text.isEmpty || resolvedSegments.contains(text)) {
        continue;
      }
      resolvedSegments.add(text);
    }

    final description =
        resolvedSegments.isEmpty
            ? context.localizations.notificationFallbackGeneric
            : resolvedSegments.join(' ');

    return HabitNotificationText(
      title: _resolveTitle(context),
      description: description,
      progressState: progressResult.state,
      scheduleState: scheduleResult.state,
      scheduleRiskState: scheduleResult.riskState,
      freshnessState: freshnessResult.state,
      premadeHabitType: context.habit.premadeHabitType,
      evaluatedChecks: List<String>.unmodifiable(evaluatedChecks),
      selectedSegmentCategories: selected
          .map((segment) => segment.category)
          .toList(growable: false),
    );
  }

  static String premadeBaseLineFor(
    PremadeHabitType type, {
    String localeCode = 'en',
  }) {
    final localizations = HabitNotificationLocaleResolver.resolveFromLocaleCode(
      localeCode,
    );
    return NotificationTemplateCatalog.resolve(
      NotificationTemplateCatalog.premadeToken(type),
      localizations,
    );
  }

  static String _resolveTitle(HabitNotificationContext context) {
    final trimmed = context.habit.name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return context.localizations.notificationFallbackTitle;
  }
}
