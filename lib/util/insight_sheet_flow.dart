import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/services/habit_strength_insight_text_service.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/habit_strength_calculator.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InsightSheetFlow {
  static const String _kInsightShownStoragePrefix =
      'habit_strength_insight_shown';

  Timer? _insightDebounce;
  bool _isInsightSheetOpen = false;
  bool _isInsightEvaluationRunning = false;
  final Set<String> _shownInsightSessionKeys = <String>{};

  void dispose() {
    _insightDebounce?.cancel();
  }

  void scheduleInsightEvaluation(
    BuildContext context, {
    required bool Function() isActive,
    bool immediate = false,
  }) {
    if (!context.mounted || !isActive()) {
      return;
    }

    _insightDebounce?.cancel();
    if (immediate) {
      unawaited(
        _evaluateAndMaybeShowInsight(context: context, isActive: isActive),
      );
      return;
    }

    _insightDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(
        _evaluateAndMaybeShowInsight(context: context, isActive: isActive),
      );
    });
  }

  Future<void> _evaluateAndMaybeShowInsight({
    required BuildContext context,
    required bool Function() isActive,
  }) async {
    if (!_canProceed(context, isActive) ||
        _isInsightSheetOpen ||
        _isInsightEvaluationRunning) {
      return;
    }

    _isInsightEvaluationRunning = true;
    try {
      final habitProvider = context.read<HabitProvider>();
      final statsProvider = context.read<HabitStatsProvider>();
      final todaysHabits = List<Habit>.from(habitProvider.todaysHabits);

      if (todaysHabits.isEmpty) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final todayKey = _dateKey(DateTime.now());

      _InsightCandidate? bestCandidate;

      for (final habit in todaysHabits) {
        final stats = statsProvider.statsForHabit(habit);
        final insight = stats.actionableInsight;
        if (insight == HabitStrengthInsight.stayConsistent) {
          continue;
        }

        if (habit.insightPopstonedUntil != null &&
            habit.insightPopstonedUntil!.isAfter(DateTime.now())) {
          continue;
        }

        if (insight == HabitStrengthInsight.pushHarder &&
            HabitStrengthInsightTextService.shouldSuppressImprovementInsight(
              habit,
            )) {
          continue;
        }

        if (insight == HabitStrengthInsight.pushHarder &&
            !habit.hasTrackingType) {
          continue;
        }

        if (insight == HabitStrengthInsight.startSmall && habit.optional) {
          continue;
        }

        // Adding key to prefs to avoid multiple same shows a day
        final storageKey = _storageKey(habit.id, insight);
        final sessionKey = '$storageKey|$todayKey';
        final shownToday = prefs.getString(storageKey) == todayKey;
        if (shownToday || _shownInsightSessionKeys.contains(sessionKey)) {
          continue;
        }

        final signalMagnitude =
            insight == HabitStrengthInsight.startSmall
                ? stats.strengthDropLast5Days
                : stats.currentStrength;

        if (bestCandidate == null ||
            signalMagnitude > bestCandidate.signalMagnitude) {
          bestCandidate = _InsightCandidate(
            habit: habit,
            insight: insight,
            stats: stats,
            storageKey: storageKey,
            signalMagnitude: signalMagnitude,
          );
        }
      }

      if (bestCandidate == null || !_canProceed(context, isActive)) {
        return;
      }

      await _showInsightSheet(
        context: context,
        isActive: isActive,
        candidate: bestCandidate,
        prefs: prefs,
        todayKey: todayKey,
      );
    } finally {
      _isInsightEvaluationRunning = false;
    }
  }

  Future<void> _showInsightSheet({
    required BuildContext context,
    required bool Function() isActive,
    required _InsightCandidate candidate,
    required SharedPreferences prefs,
    required String todayKey,
  }) async {
    if (!_canProceed(context, isActive)) {
      return;
    }

    final sessionKey = '${candidate.storageKey}|$todayKey';
    _shownInsightSessionKeys.add(sessionKey);
    await prefs.setString(candidate.storageKey, todayKey);

    if (!_canProceed(context, isActive)) {
      return;
    }

    // For pushHarder Getting recommendation if needed (from 1 to 3 times jump)
    final recommendation = _buildTargetRecommendation(candidate);
    final isMotivationOnly = recommendation == null;
    final isOptionalPushHarder =
        candidate.insight == HabitStrengthInsight.pushHarder &&
        candidate.habit.optional;

    final localizations = AppLocalizations.of(context)!;
    final fromValue =
        recommendation == null
            ? null
            : _formatRecommendationValue(
              recommendation,
              recommendation.currentValue,
            );
    final toValue =
        recommendation == null
            ? null
            : _formatRecommendationValue(
              recommendation,
              recommendation.recommendedValue,
            );

    final insightCopy = HabitStrengthInsightTextService.buildDialogCopy(
      localizations: localizations,
      habit: candidate.habit,
      insight: candidate.insight,
      isMotivationOnly: isMotivationOnly,
      todayKey: todayKey,
      dropPercent: (candidate.stats.strengthDropLast5Days * 100).round(),
      strengthPercent: (candidate.stats.currentStrength * 100).round(),
      fromValue: fromValue,
      toValue: toValue,
    );

    final title =
        isOptionalPushHarder
            ? 'Ready to level up ${candidate.habit.name}?'
            : insightCopy.title;

    final desc =
        isOptionalPushHarder
            ? "You're getting really consistent with this habit. Consider not making it optional to push yourself a bit more. Do you want to update this habit now?"
            : insightCopy.description;

    final primaryLabel =
        isOptionalPushHarder ? 'Update now' : insightCopy.primaryLabel;

    _isInsightSheetOpen = true;
    try {
      await showDialogSheet(
        context: context,
        builder: (dialogContext) {
          return NewDefaultDialog(
            title: title,
            desc: desc,
            primaryButtonLabel: primaryLabel,
            showSecondaryButton: !isMotivationOnly,
            secondaryButtonLabel: 'Later',
            onSecondaryButtonPressed: () {
              // Update habit insight sheet popstoned until date
              candidate.habit.insightPopstonedUntil = DateTime.now().add(
                const Duration(days: 3),
              );
              Navigator.pop(dialogContext);
            },
            onPrimaryButtonPressed: () {
              Navigator.pop(dialogContext);
              if (!_canProceed(context, isActive)) {
                return;
              }
              if (isOptionalPushHarder) {
                _applyOptionalPushHarderUpdate(context, candidate.habit);
                return;
              }
              if (recommendation != null) {
                _applyRecommendation(context, candidate.habit, recommendation);
              }
            },
          );
        },
      );
    } finally {
      _isInsightSheetOpen = false;
    }
  }

  _TargetRecommendation? _buildTargetRecommendation(
    _InsightCandidate candidate,
  ) {
    final habit = candidate.habit;
    final isStartSmall = candidate.insight == HabitStrengthInsight.startSmall;

    if (isStartSmall &&
        HabitStrengthInsightTextService.shouldSuppressTargetDecreaseInsight(
          habit,
        )) {
      return null;
    }

    if (habit.tracksAmount) {
      final current = habit.amount;
      final recommended =
          isStartSmall
              ? _decreaseRecommendation(
                current,
                candidate.stats.strengthDropLast5Days,
              )
              : _increaseRecommendation(
                current,
                candidate.stats.currentStrength,
              );

      if (recommended == current) {
        return null;
      }

      final label =
          habit.amountLabel.trim().isEmpty
              ? AmountLabelPreset.times.plural
              : habit.amountLabel.trim();

      return _TargetRecommendation(
        kind: _TargetKind.amount,
        currentValue: current,
        recommendedValue: recommended,
        unitLabel: label,
      );
    }

    if (habit.tracksDuration) {
      final current = habit.duration;
      final recommended =
          isStartSmall
              ? _decreaseRecommendation(
                current,
                candidate.stats.strengthDropLast5Days,
              )
              : _increaseRecommendation(
                current,
                candidate.stats.currentStrength,
              );

      if (recommended == current) {
        return null;
      }

      return _TargetRecommendation(
        kind: _TargetKind.duration,
        currentValue: current,
        recommendedValue: recommended,
        unitLabel: 'min',
      );
    }

    return null;
  }

  int _decreaseRecommendation(int current, double dropFraction) {
    if (current <= 1) {
      return 1;
    }

    final factor = (0.10 + (dropFraction * 0.50)).clamp(0.10, 0.35);
    int next = (current * (1 - factor)).round();
    next = next.clamp(1, current).toInt();

    if (next == current) {
      next = current - 1;
    }

    return math.max(1, next);
  }

  int _increaseRecommendation(int current, double currentStrength) {
    final factor = (0.08 + ((currentStrength - 0.85).clamp(0.0, 0.15) * 0.8))
        .clamp(0.08, 0.20);
    final delta = math.max(1, (current * factor).round());
    return current + delta;
  }

  String _formatRecommendationValue(
    _TargetRecommendation recommendation,
    int value,
  ) {
    if (recommendation.kind == _TargetKind.duration) {
      return '$value min';
    }
    return '$value ${resolveAmountLabelForValue(recommendation.unitLabel, value)}';
  }

  void _applyRecommendation(
    BuildContext context,
    Habit habit,
    _TargetRecommendation recommendation,
  ) {
    final habitProvider = context.read<HabitProvider>();
    final updated = habit.copy();

    if (recommendation.kind == _TargetKind.amount) {
      updated.amount = recommendation.recommendedValue;
      if (updated.amountCompleted > updated.amount) {
        updated.amountCompleted = updated.amount;
      }
    } else {
      updated.duration = recommendation.recommendedValue;
      if (updated.durationCompleted > updated.duration) {
        updated.durationCompleted = updated.duration;
      }
    }

    habitProvider.updateHabit(updated);
  }

  void _applyOptionalPushHarderUpdate(BuildContext context, Habit habit) {
    final habitProvider = context.read<HabitProvider>();
    final updated = habit.copy()..optional = false;
    habitProvider.updateHabit(updated);
  }

  bool _canProceed(BuildContext context, bool Function() isActive) {
    return context.mounted && isActive();
  }

  static String _storageKey(int habitId, HabitStrengthInsight insight) {
    return '${_kInsightShownStoragePrefix}_${habitId}_${insight.name}';
  }

  static String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}

class _InsightCandidate {
  const _InsightCandidate({
    required this.habit,
    required this.insight,
    required this.stats,
    required this.storageKey,
    required this.signalMagnitude,
  });

  final Habit habit;
  final HabitStrengthInsight insight;
  final HabitStatsData stats;
  final String storageKey;
  final double signalMagnitude;
}

enum _TargetKind { amount, duration }

class _TargetRecommendation {
  const _TargetRecommendation({
    required this.kind,
    required this.currentValue,
    required this.recommendedValue,
    required this.unitLabel,
  });

  final _TargetKind kind;
  final int currentValue;
  final int recommendedValue;
  final String unitLabel;
}
