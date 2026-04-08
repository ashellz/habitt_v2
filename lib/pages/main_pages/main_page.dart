import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/util/habit_strength_calculator.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/habits/new_habits.dart';
import 'package:habitt/widgets/main_page/main_page_top_section.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    required this.isActive,
    required this.lifecycleTick,
  });

  final bool isActive;
  final int lifecycleTick;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const String _kInsightShownStoragePrefix =
      'habit_strength_insight_shown';

  static const List<String> _noTargetMotivationMessagesDecrease = [
    'You added this habit for a reason, don\'t fall behind now.',
    'Do not lose your edge now. Finish what you started.',
    'You set this goal. Keep your word to yourself today.',
    'No excuses today. Stay disciplined and keep this habit alive.',
    'Don\'t let this habit slip. Complete your goal today and don\'t risk it.',
    'Stay focused. Falling off once makes it easier to fall again.',
    'You are not done on this habit yet. Keep pressure on and stay consistent.',
    'Protect your streak. One solid effort today keeps momentum alive.',
    'Do not negotiate with laziness. Execute the habit and move on.',
    'You\'re falling behind on this habit. You know what to do.',
    'You came too far to coast now. Lock in and complete it.',
    'This is your promise to yourself. Keep it.',
    'Discipline over mood. Get it done.',
  ];

  late final ConfettiController _confettiController;
  bool _wasAllCompleted = false;
  bool _initializedCompletionState = false;
  late VoidCallback _habitProviderListener;
  bool _hasHabitListener = false;
  bool _isInsightSheetOpen = false;
  bool _isInsightEvaluationRunning = false;
  Timer? _insightDebounce;
  final Set<String> _shownInsightSessionKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _attachHabitProviderListener();
      _scheduleInsightEvaluation(immediate: true);
    });
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final becameActive = !oldWidget.isActive && widget.isActive;
    final lifecycleChanged = oldWidget.lifecycleTick != widget.lifecycleTick;
    if (becameActive || (lifecycleChanged && widget.isActive)) {
      _scheduleInsightEvaluation(immediate: true);
    }
  }

  @override
  void dispose() {
    _insightDebounce?.cancel();
    if (_hasHabitListener) {
      try {
        context.read<HabitProvider>().removeListener(_habitProviderListener);
      } catch (_) {
        // Provider may not be available during teardown.
      }
    }
    _confettiController.dispose();
    super.dispose();
  }

  void _attachHabitProviderListener() {
    if (_hasHabitListener) {
      return;
    }

    final habitProvider = context.read<HabitProvider>();
    _habitProviderListener = () {
      if (!mounted || !widget.isActive) {
        return;
      }
      _scheduleInsightEvaluation();
    };
    habitProvider.addListener(_habitProviderListener);
    _hasHabitListener = true;
  }

  void _scheduleInsightEvaluation({bool immediate = false}) {
    if (!widget.isActive) {
      return;
    }

    _insightDebounce?.cancel();
    if (immediate) {
      _evaluateAndMaybeShowInsight();
      return;
    }

    _insightDebounce = Timer(const Duration(milliseconds: 450), () {
      _evaluateAndMaybeShowInsight();
    });
  }

  Future<void> _evaluateAndMaybeShowInsight() async {
    if (!mounted ||
        !widget.isActive ||
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

        if (insight == HabitStrengthInsight.pushHarder &&
            habit.amount <= 0 &&
            habit.duration <= 0) {
          continue;
        }

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

      if (bestCandidate == null || !mounted || !widget.isActive) {
        return;
      }

      await _showInsightSheet(
        candidate: bestCandidate,
        prefs: prefs,
        todayKey: todayKey,
      );
    } finally {
      _isInsightEvaluationRunning = false;
    }
  }

  Future<void> _showInsightSheet({
    required _InsightCandidate candidate,
    required SharedPreferences prefs,
    required String todayKey,
  }) async {
    if (!mounted || !widget.isActive) {
      return;
    }

    final sessionKey = '${candidate.storageKey}|$todayKey';
    _shownInsightSessionKeys.add(sessionKey);
    await prefs.setString(candidate.storageKey, todayKey);
    if (!mounted || !widget.isActive) {
      return;
    }

    final recommendation = _buildTargetRecommendation(candidate);
    final isMotivationOnly = recommendation == null;

    final title =
        isMotivationOnly
            ? 'Keep pushing ${candidate.habit.name}'
            : candidate.insight == HabitStrengthInsight.startSmall
            ? 'Lower target for ${candidate.habit.name}'
            : 'Increase target for ${candidate.habit.name}';

    final desc =
        isMotivationOnly
            ? _motivationDescription(candidate, todayKey)
            : _recommendationDescription(candidate, recommendation);

    final primaryLabel =
        isMotivationOnly
            ? _gotItLabel(candidate, todayKey)
            : candidate.insight == HabitStrengthInsight.startSmall
            ? 'Apply decrease'
            : 'Apply increase';

    _isInsightSheetOpen = true;
    try {
      await showDialogSheet(
        context: context,
        builder: (dialogContext) {
          return NewDefaultDialog(
            title: title,
            desc: desc,
            primaryButtonLabel: primaryLabel,
            secondaryButtonLabel: 'Later',
            onPrimaryButtonPressed: () {
              Navigator.pop(dialogContext);
              if (!mounted || !widget.isActive) {
                return;
              }
              if (recommendation != null) {
                _applyRecommendation(candidate.habit, recommendation);
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

    if (habit.amount > 0) {
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
          habit.amountLabel.trim().isEmpty ? 'times' : habit.amountLabel.trim();

      return _TargetRecommendation(
        kind: _TargetKind.amount,
        currentValue: current,
        recommendedValue: recommended,
        unitLabel: label,
      );
    }

    if (habit.duration > 0) {
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

  String _recommendationDescription(
    _InsightCandidate candidate,
    _TargetRecommendation recommendation,
  ) {
    final fromValue =
        recommendation.kind == _TargetKind.duration
            ? '${recommendation.currentValue} min'
            : '${recommendation.currentValue} ${recommendation.unitLabel}';

    final toValue =
        recommendation.kind == _TargetKind.duration
            ? '${recommendation.recommendedValue} min'
            : '${recommendation.recommendedValue} ${recommendation.unitLabel}';

    if (candidate.insight == HabitStrengthInsight.startSmall) {
      final drop = (candidate.stats.strengthDropLast5Days * 100).round();
      return 'Strength dropped by $drop% in the last 5 days. Recommended target: $fromValue -> $toValue to improve consistency.';
    }

    final strength = (candidate.stats.currentStrength * 100).round();
    return 'Strength is stable at $strength%. Recommended target: $fromValue -> $toValue to keep growing.';
  }

  String _motivationDescription(_InsightCandidate candidate, String todayKey) {
    final source = _noTargetMotivationMessagesDecrease;
    final idx = (candidate.habit.id ^ todayKey.hashCode).abs() % source.length;
    return source[idx];
  }

  String _gotItLabel(_InsightCandidate candidate, String todayKey) {
    final idx = (candidate.habit.id ^ todayKey.hashCode).abs();
    final emoji = idx.isEven ? '💪' : '🚀';
    return '$emoji Got it';
  }

  void _applyRecommendation(Habit habit, _TargetRecommendation recommendation) {
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

  static String _storageKey(int habitId, HabitStrengthInsight insight) {
    return '${_kInsightShownStoragePrefix}_${habitId}_${insight.name}';
  }

  static String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const bottomNavBar = 86;

    final habits = context.watch<HabitProvider>().todaysHabits;

    final bool allCompleted =
        habits.isNotEmpty && habits.every((habit) => habit.completed);
    if (!_initializedCompletionState) {
      _wasAllCompleted = allCompleted;
      _initializedCompletionState = true;
    } else {
      if (allCompleted && !_wasAllCompleted) {
        _confettiController.play();
      } else if (!allCompleted && _wasAllCompleted) {
        _confettiController.stop();
      }
      _wasAllCompleted = allCompleted;
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 2, child: Container(color: cp.bg)),
              Expanded(child: Container(color: cp.habitBg)),
            ],
          ),
          ListView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            physics: const ClampingScrollPhysics(),
            children: [
              MainPageTopSection(),
              SizedBox(height: 20),
              Container(
                color: cp.habitBg,
                child: Column(
                  children: [
                    NewCategoriesList(),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: NewHabits(),
                    ),
                    SizedBox(height: bottomPadding + bottomNavBar),
                  ],
                ),
              ),
            ],
          ),

          // Confetti celebration when all habits are completed
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                minimumSize: const Size(10, 5),
                maximumSize: const Size(20, 10),
                emissionFrequency: 0.08,
                numberOfParticles: 24,
                maxBlastForce: 20,
                minBlastForce: 5,
                gravity: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
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
