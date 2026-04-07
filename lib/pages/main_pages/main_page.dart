import 'dart:async';

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
import 'package:habitt/widgets/sheets/habit_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinycolor2/tinycolor2.dart';

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

    final title =
        candidate.insight == HabitStrengthInsight.startSmall
            ? 'Try a smaller target for ${candidate.habit.name}'
            : 'You are consistent with ${candidate.habit.name}';

    final desc =
        candidate.insight == HabitStrengthInsight.startSmall
            ? 'Strength dropped by ${(candidate.stats.strengthDropLast5Days * 100).round()}% in the last 5 days. Consider lowering amount or duration to rebuild consistency.'
            : 'Your habit strength is stable above ${(candidate.stats.currentStrength * 100).round()}%, and you are sometimes over-performing. You can gently increase the target if you want.';

    final primaryLabel =
        candidate.insight == HabitStrengthInsight.startSmall
            ? 'Adjust target'
            : 'Tune target';

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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !widget.isActive) {
                  return;
                }
                _openHabitEditSheet(candidate.habit);
              });
            },
          );
        },
      );
    } finally {
      _isInsightSheetOpen = false;
    }
  }

  Future<void> _openHabitEditSheet(Habit habit) async {
    final cp = context.read<ColorProvider>();

    await showModalBottomSheet(
      context: context,
      backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
      barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
      isScrollControlled: true,
      builder: (_) => HabitSheet(habit: habit),
    );
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
