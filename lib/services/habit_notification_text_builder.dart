import 'dart:math' as math;

import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/services/notification_text/locale_resolver.dart';
import 'package:habitt/services/notification_text/rules/freshness_rule.dart';
import 'package:habitt/services/notification_text/rules/progress_rule.dart';
import 'package:habitt/services/notification_text/rules/schedule_rule.dart';
import 'package:habitt/services/notification_text/template_catalog.dart';
import 'package:habitt/services/notification_text/types.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
import 'package:habitt/util/get_capitalized_first.dart';

export 'package:habitt/services/notification_text/types.dart';

class HabitNotificationExamples {
  static Map<PremadeHabitType, String> premadeTypeDescriptions({
    String localeCode = 'en',
  }) {
    final localizations = HabitNotificationLocaleResolver.resolveFromLocaleCode(
      localeCode,
    );
    final result = <PremadeHabitType, String>{};
    result[PremadeHabitType.goToBedEarly] =
        localizations.notificationEncourageGoToBedEarly1;
    result[PremadeHabitType.brushTeeth] =
        localizations.notificationEncourageBrushTeeth1;
    result[PremadeHabitType.skinCare] =
        localizations.notificationEncourageSkinCare1;
    result[PremadeHabitType.wakeUpEarly] =
        localizations.notificationEncourageWakeUpEarly1;
    result[PremadeHabitType.shower] =
        localizations.notificationEncourageShower1;
    result[PremadeHabitType.running] =
        localizations.notificationEncourageRunning1;
    result[PremadeHabitType.walk] = localizations.notificationEncourageWalk1;
    result[PremadeHabitType.gym] = localizations.notificationEncourageGym1;
    result[PremadeHabitType.nutrition] =
        localizations.notificationEncourageNutrition1;
    result[PremadeHabitType.medications] =
        localizations.notificationEncourageMedications1;
    result[PremadeHabitType.drinkWater] =
        localizations.notificationEncourageDrinkWater1;
    result[PremadeHabitType.studying] =
        localizations.notificationEncourageStudying1;
    result[PremadeHabitType.work] = localizations.notificationEncourageWork1;
    result[PremadeHabitType.research] =
        localizations.notificationEncourageResearch1;
    result[PremadeHabitType.productivitySession] =
        localizations.notificationEncourageProductivitySession1;
    result[PremadeHabitType.read] = localizations.notificationEncourageRead1;
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
  static HabitNotificationText build(HabitNotificationContext context) {
    final evaluatedChecks = <String>[];

    final progressResult = ProgressNotificationRule.evaluate(
      context,
      evaluatedChecks,
    );

    final scheduleResult = ScheduleNotificationRule.evaluate(
      context,
      evaluatedChecks,
    );

    final freshnessResult = FreshnessNotificationRule.evaluate(
      context,
      evaluatedChecks,
    );

    final description = _buildCombinedDescription(
      context: context,
      progressResult: progressResult,
      scheduleResult: scheduleResult,
      freshnessResult: freshnessResult,
      evaluatedChecks: evaluatedChecks,
    );

    return HabitNotificationText(
      title: _resolveTitle(context),
      description: description.trim(),
      progressState: progressResult.state,
      scheduleState: scheduleResult.state,
      scheduleRiskState: scheduleResult.riskState,
      freshnessState: freshnessResult.state,
      premadeHabitType: context.habit.premadeHabitType,
      evaluatedChecks: List<String>.unmodifiable(evaluatedChecks),
      selectedSegmentCategories: const [
        HabitNotificationSegmentCategory.identity,
      ],
    );
  }

  static String premadeBaseLineFor(
    PremadeHabitType type, {
    String localeCode = 'en',
  }) {
    final localizations = HabitNotificationLocaleResolver.resolveFromLocaleCode(
      localeCode,
    );
    final variants = _encouragementVariants(localizations, type);
    if (variants.isEmpty) {
      return localizations.notificationEncourageGeneric1;
    }
    return variants.first;
  }

  static String _buildCombinedDescription({
    required HabitNotificationContext context,
    required ProgressRuleResult progressResult,
    required ScheduleRuleResult scheduleResult,
    required FreshnessRuleResult freshnessResult,
    required List<String> evaluatedChecks,
  }) {
    final l = context.localizations;

    final isOneOff =
        scheduleResult.riskState ==
        HabitNotificationScheduleRiskState.atRiskIfSkipToday;
    final isAlmostDone =
        progressResult.state == HabitNotificationProgressState.almostDone;

    if (!isOneOff && !isAlmostDone && math.Random().nextDouble() < 0.5) {
      evaluatedChecks.add('combined.noTracking.random');
      return NotificationTemplateCatalog.resolve(
        const NotificationTemplateToken(
          key: NotificationTemplateKey.progressNoTracking,
        ),
        l,
      );
    }

    final type = context.habit.premadeHabitType;
    evaluatedChecks.add('premadeType');
    final family = _resolveFamily(type);
    final encouragement = _pickEncouragement(context, type);

    if (isOneOff && _supportsOneOff(family)) {
      evaluatedChecks.add('combined.oneOff');
      final periodLabel =
          context.habit.scheduleType == ScheduleType.monthly
              ? l.notificationPeriodMonthly
              : l.notificationPeriodWeekly;
      return l.notificationCombinedOneOff(encouragement, periodLabel);
    }

    final isFresh =
        freshnessResult.state == HabitNotificationFreshnessState.brandNew ||
        freshnessResult.state == HabitNotificationFreshnessState.newHabit;

    switch (family) {
      case _PremadeFamily.goToBedEarly:
      case _PremadeFamily.hygieneSimple:
        if (isFresh) {
          evaluatedChecks.add('combined.fresh');
          final days = (context.daysSinceCreated + 1).toString();
          return l.notificationCombinedFresh(days, encouragement);
        }
        evaluatedChecks.add('combined.general');
        return _pickCombinedGeneral(l, _encouragementVariants(l, type));
      case _PremadeFamily.shower:
        final showerProgress = _buildAmountProgressMessage(
          context,
          progressResult,
          encouragement,
        );
        if (showerProgress != null) {
          evaluatedChecks.add('combined.shower.amount');
          return showerProgress;
        }
        if (isFresh) {
          evaluatedChecks.add('combined.fresh');
          final days = (context.daysSinceCreated + 1).toString();
          return l.notificationCombinedFresh(days, encouragement);
        }
        evaluatedChecks.add('combined.general');
        return _pickCombinedGeneral(l, _encouragementVariants(l, type));
      case _PremadeFamily.activityGroup:
        final progressMessage = _buildProgressMessage(
          context,
          progressResult,
          encouragement,
        );
        if (progressMessage != null) {
          evaluatedChecks.add('combined.progress');
          return progressMessage;
        }
        if (isFresh) {
          evaluatedChecks.add('combined.fresh');
          final days = (context.daysSinceCreated + 1).toString();
          return l.notificationCombinedFresh(days, encouragement);
        }
        evaluatedChecks.add('combined.general');
        return _pickCombinedGeneral(l, _encouragementVariants(l, type));
      case _PremadeFamily.none:
        final genericProgress = _buildProgressMessage(
          context,
          progressResult,
          l.notificationEncourageGeneric1,
        );
        if (genericProgress != null) {
          evaluatedChecks.add('combined.progress.generic');
          return genericProgress;
        }
        if (isFresh) {
          evaluatedChecks.add('combined.fresh.generic');
          final days = (context.daysSinceCreated + 1).toString();
          return l.notificationCombinedFresh(
            days,
            l.notificationEncourageGeneric1,
          );
        }
        evaluatedChecks.add('combined.generic');
        return _pickCombinedGeneral(l, [
          l.notificationEncourageGeneric1,
          l.notificationEncourageGeneric2,
          l.notificationEncourageGeneric3,
        ]);
    }
  }

  static String _pickCombinedGeneral(
    AppLocalizations l,
    List<String> variants,
  ) {
    final options = [
      ...variants.map((v) => l.notificationCombinedGeneral(capitalizeFirst(v))),
      ...l.notificationProgressNoTracking
          .split('|')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty),
    ];
    return options[math.Random().nextInt(options.length)];
  }

  static String? _buildAmountProgressMessage(
    HabitNotificationContext context,
    ProgressRuleResult progressResult,
    String encouragement,
  ) {
    if (!context.habit.tracksAmount || context.habit.amount <= 0) {
      return null;
    }
    return _buildProgressMessage(context, progressResult, encouragement);
  }

  static String? _buildProgressMessage(
    HabitNotificationContext context,
    ProgressRuleResult progressResult,
    String encouragement,
  ) {
    final l = context.localizations;
    final habit = context.habit;

    if (habit.tracksAmount && habit.amount > 0) {
      final completed = habit.amountCompleted.clamp(0, habit.amount);
      final remaining = (habit.amount - completed).clamp(0, habit.amount);

      if (progressResult.state == HabitNotificationProgressState.notStarted) {
        return l.notificationCombinedAmountNotStarted(encouragement);
      }

      if (progressResult.state == HabitNotificationProgressState.almostDone) {
        final label = resolveAmountLabelForValue(
          habit.amountLabel,
          remaining,
          l,
        );
        final remainingText = '$remaining $label';
        return l.notificationCombinedAmountAlmostDone(
          encouragement,
          remainingText,
        );
      }

      if (progressResult.state == HabitNotificationProgressState.inProgress) {
        final label = resolveAmountLabelForValue(
          habit.amountLabel,
          habit.amount,
          l,
        );
        final progressText = '$completed/${habit.amount} $label';
        return l.notificationCombinedAmountInProgress(
          encouragement,
          progressText,
        );
      }

      if (progressResult.state == HabitNotificationProgressState.completed) {
        return null;
      }

      return null;
    }

    if (habit.tracksDuration && habit.duration > 0) {
      final completed = habit.durationCompleted.clamp(0, habit.duration);
      final remaining = (habit.duration - completed).clamp(0, habit.duration);

      if (progressResult.state == HabitNotificationProgressState.notStarted) {
        return l.notificationCombinedDurationNotStarted(encouragement);
      }

      if (progressResult.state == HabitNotificationProgressState.almostDone) {
        final remainingText = _formatDuration(remaining);
        return l.notificationCombinedDurationAlmostDone(
          encouragement,
          remainingText,
        );
      }

      if (progressResult.state == HabitNotificationProgressState.inProgress) {
        final progressText =
            '${_formatDuration(completed)}/${_formatDuration(habit.duration)}';
        return l.notificationCombinedDurationInProgress(
          encouragement,
          progressText,
        );
      }

      if (progressResult.state == HabitNotificationProgressState.completed) {
        return null;
      }

      return null;
    }

    return null;
  }

  static String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (remainder == 0) {
      return '$hours h';
    }
    return '$hours h $remainder min';
  }

  static _PremadeFamily _resolveFamily(PremadeHabitType? type) {
    if (type == null) {
      return _PremadeFamily.none;
    }

    switch (type) {
      case PremadeHabitType.goToBedEarly:
        return _PremadeFamily.goToBedEarly;
      case PremadeHabitType.brushTeeth:
      case PremadeHabitType.skinCare:
      case PremadeHabitType.wakeUpEarly:
        return _PremadeFamily.hygieneSimple;
      case PremadeHabitType.shower:
        return _PremadeFamily.shower;
      case PremadeHabitType.running:
      case PremadeHabitType.walk:
      case PremadeHabitType.gym:
      case PremadeHabitType.nutrition:
      case PremadeHabitType.medications:
      case PremadeHabitType.drinkWater:
      case PremadeHabitType.studying:
      case PremadeHabitType.work:
      case PremadeHabitType.research:
      case PremadeHabitType.productivitySession:
      case PremadeHabitType.read:
        return _PremadeFamily.activityGroup;
      case PremadeHabitType.praying:
        return _PremadeFamily.none;
    }
  }

  static bool _supportsOneOff(_PremadeFamily family) {
    return family != _PremadeFamily.none;
  }

  static String _pickEncouragement(
    HabitNotificationContext context,
    PremadeHabitType? type,
  ) {
    final variants = _encouragementVariants(context.localizations, type);
    if (variants.isEmpty) {
      return context.localizations.notificationEncourageGeneric1;
    }
    return variants[math.Random().nextInt(variants.length)];
  }

  static List<String> _encouragementVariants(
    AppLocalizations l,
    PremadeHabitType? type,
  ) {
    switch (type) {
      case PremadeHabitType.goToBedEarly:
        return [
          l.notificationEncourageGoToBedEarly1,
          l.notificationEncourageGoToBedEarly2,
          l.notificationEncourageGoToBedEarly3,
          l.notificationEncourageGoToBedEarly4,
          l.notificationEncourageGoToBedEarly5,
          l.notificationEncourageGoToBedEarly6,
          l.notificationEncourageGoToBedEarly7,
          l.notificationEncourageGoToBedEarly8,
          l.notificationEncourageGoToBedEarly9,
          l.notificationEncourageGoToBedEarly10,
        ];
      case PremadeHabitType.brushTeeth:
        return [
          l.notificationEncourageBrushTeeth1,
          l.notificationEncourageBrushTeeth2,
          l.notificationEncourageBrushTeeth3,
        ];
      case PremadeHabitType.skinCare:
        return [
          l.notificationEncourageSkinCare1,
          l.notificationEncourageSkinCare2,
          l.notificationEncourageSkinCare3,
        ];
      case PremadeHabitType.wakeUpEarly:
        return [
          l.notificationEncourageWakeUpEarly1,
          l.notificationEncourageWakeUpEarly2,
          l.notificationEncourageWakeUpEarly3,
        ];
      case PremadeHabitType.shower:
        return [
          l.notificationEncourageShower1,
          l.notificationEncourageShower2,
          l.notificationEncourageShower3,
        ];
      case PremadeHabitType.running:
        return [
          l.notificationEncourageRunning1,
          l.notificationEncourageRunning2,
          l.notificationEncourageRunning3,
        ];
      case PremadeHabitType.walk:
        return [
          l.notificationEncourageWalk1,
          l.notificationEncourageWalk2,
          l.notificationEncourageWalk3,
        ];
      case PremadeHabitType.gym:
        return [
          l.notificationEncourageGym1,
          l.notificationEncourageGym2,
          l.notificationEncourageGym3,
        ];
      case PremadeHabitType.nutrition:
        return [
          l.notificationEncourageNutrition1,
          l.notificationEncourageNutrition2,
          l.notificationEncourageNutrition3,
        ];
      case PremadeHabitType.medications:
        return [
          l.notificationEncourageMedications1,
          l.notificationEncourageMedications2,
          l.notificationEncourageMedications3,
        ];
      case PremadeHabitType.drinkWater:
        return [
          l.notificationEncourageDrinkWater1,
          l.notificationEncourageDrinkWater2,
          l.notificationEncourageDrinkWater3,
        ];
      case PremadeHabitType.studying:
        return [
          l.notificationEncourageStudying1,
          l.notificationEncourageStudying2,
          l.notificationEncourageStudying3,
        ];
      case PremadeHabitType.work:
        return [
          l.notificationEncourageWork1,
          l.notificationEncourageWork2,
          l.notificationEncourageWork3,
        ];
      case PremadeHabitType.research:
        return [
          l.notificationEncourageResearch1,
          l.notificationEncourageResearch2,
          l.notificationEncourageResearch3,
        ];
      case PremadeHabitType.productivitySession:
        return [
          l.notificationEncourageProductivitySession1,
          l.notificationEncourageProductivitySession2,
          l.notificationEncourageProductivitySession3,
        ];
      case PremadeHabitType.read:
        return [
          l.notificationEncourageRead1,
          l.notificationEncourageRead2,
          l.notificationEncourageRead3,
        ];
      case PremadeHabitType.praying:
      case null:
        return [
          l.notificationEncourageGeneric1,
          l.notificationEncourageGeneric2,
          l.notificationEncourageGeneric3,
          l.notificationProgressNoTracking,
        ];
    }
  }

  static String _resolveTitle(HabitNotificationContext context) {
    final trimmed = context.habit.name.trim();
    final name = trimmed.isNotEmpty ? trimmed : context.localizations.notificationFallbackTitle;
    final icon = context.habit.iconPath.trim();
    if (icon.isNotEmpty) {
      return '$icon $name';
    }
    return name;
  }
}

enum _PremadeFamily { goToBedEarly, hygieneSimple, shower, activityGroup, none }
