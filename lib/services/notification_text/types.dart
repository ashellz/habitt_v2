import 'dart:math' as math;

import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/premade_habit_type.dart';

import 'template_catalog.dart';

typedef HabitAppearsOnDay = bool Function(Habit habit, DateTime day);

enum HabitNotificationProgressState {
  noTrackingGoal,
  notStarted,
  inProgress,
  almostDone,
  completed,
}

enum HabitNotificationScheduleState {
  daily,
  weeklyOnTrack,
  weeklyLastWindow,
  weeklyGoalReached,
  weeklyImpossible,
  monthlyOnTrack,
  monthlyLastWindow,
  monthlyGoalReached,
  monthlyImpossible,
  custom,
}

enum HabitNotificationScheduleRiskState {
  none,
  onTrack,
  atRiskIfSkipToday,
  impossibleEvenIfDoneToday,
  alreadyReached,
}

enum HabitNotificationFreshnessState { brandNew, newHabit, established }

enum HabitNotificationSegmentCategory {
  identity,
  progress,
  schedule,
  freshness,
  amountLabel,
  optional,
  fallback,
}

class HabitNotificationContext {
  HabitNotificationContext({
    required this.habit,
    required this.scheduledAt,
    required this.appearsOnDay,
    required this.localizations,
    DateTime? now,
    this.customSingulars,
  }) : now = (now ?? DateTime.now()).toUtc();

  final Habit habit;
  final DateTime scheduledAt;
  final DateTime now;
  final HabitAppearsOnDay appearsOnDay;
  final AppLocalizations localizations;
  final Map<String, String>? customSingulars;

  DateTime get scheduledDay =>
      DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);

  DateTime get createdDay {
    final createdLocal = habit.createdAt.toLocal();
    return DateTime(createdLocal.year, createdLocal.month, createdLocal.day);
  }

  int get daysSinceCreated {
    return math.max(0, scheduledDay.difference(createdDay).inDays);
  }
}

class HabitNotificationSegment {
  const HabitNotificationSegment({
    required this.category,
    required this.priority,
    required this.template,
    required this.debugKey,
  });

  final HabitNotificationSegmentCategory category;
  final int priority;
  final NotificationTemplateToken template;
  final String debugKey;
}

class HabitNotificationText {
  const HabitNotificationText({
    required this.title,
    required this.description,
    required this.progressState,
    required this.scheduleState,
    required this.scheduleRiskState,
    required this.freshnessState,
    required this.premadeHabitType,
    required this.evaluatedChecks,
    required this.selectedSegmentCategories,
  });

  final String title;
  final String description;
  final HabitNotificationProgressState progressState;
  final HabitNotificationScheduleState scheduleState;
  final HabitNotificationScheduleRiskState scheduleRiskState;
  final HabitNotificationFreshnessState freshnessState;
  final PremadeHabitType? premadeHabitType;
  final List<String> evaluatedChecks;
  final List<HabitNotificationSegmentCategory> selectedSegmentCategories;
}
