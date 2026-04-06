import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/habit_details_page.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_category_title.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_widget.dart';

class NewHabitCategory extends StatefulWidget {
  const NewHabitCategory({
    super.key,
    this.isFirst = false,
    this.reorderActive = false,
    this.reorderProgress = 0,
    this.reorderSwapPoint = 0.48,
    this.reorderDurationMs = 760,
    this.useFallbackAnimation = false,
    this.fallbackVisibleHabits = 3,
    this.showTitle = true,
    required this.showOptionalHabits,
    required this.category,
    required this.habits,
    required this.isToday,
  });

  final bool isFirst;
  final bool reorderActive;
  final double reorderProgress;
  final double reorderSwapPoint;
  final int reorderDurationMs;
  final bool useFallbackAnimation;
  final int fallbackVisibleHabits;
  final Category category;
  final bool showOptionalHabits;
  final List<Habit> habits;
  final bool isToday;
  final bool showTitle;

  @override
  State<NewHabitCategory> createState() => _NewHabitCategoryState();
}

class _NewHabitCategoryState extends State<NewHabitCategory>
    with SingleTickerProviderStateMixin {
  static const int _extraRevealBaseDelayMs = 350;
  static const int _extraRevealFadeDurationMs = 120;
  static const int _collapseBaseFadeDurationMs = 120;

  late final AnimationController _extraRevealController;
  bool _isRevealingExtras = false;

  int get _maxExtraRevealDurationMs =>
      _extraRevealBaseDelayMs + _extraRevealFadeDurationMs;

  int _extraHabitsCountForWidget(NewHabitCategory widgetConfig) {
    final categoryHabits =
        widgetConfig.habits
            .where(
              (habit) => habit.categoryId == widgetConfig.category.id, //&&
              //!habit.optional,
            )
            .length;

    return (categoryHabits - widgetConfig.fallbackVisibleHabits).clamp(
      0,
      categoryHabits,
    );
  }

  void _startExtraReveal() {
    _extraRevealController
      ..value = 0
      ..forward();
    if (!_isRevealingExtras) {
      setState(() {
        _isRevealingExtras = true;
      });
    }
  }

  double _extraRevealOpacityForIndex(int index, int totalHabits) {
    if (!_isRevealingExtras) {
      return 1;
    }

    final extraCount = (totalHabits - widget.fallbackVisibleHabits).clamp(
      0,
      totalHabits,
    );
    if (extraCount <= 0 || index < widget.fallbackVisibleHabits) {
      return 1;
    }

    final bottomMostExtraIndex = totalHabits - 1;
    final extraOrderFromBottom = (bottomMostExtraIndex - index).clamp(
      0,
      extraCount,
    );
    final delayStep = _extraRevealBaseDelayMs / extraCount;
    final delayMs = (_extraRevealBaseDelayMs -
            (extraOrderFromBottom * delayStep))
        .clamp(0, _extraRevealBaseDelayMs.toDouble());

    final elapsedMs = _extraRevealController.value * _maxExtraRevealDurationMs;
    final opacity = ((elapsedMs - delayMs) / _extraRevealFadeDurationMs).clamp(
      0.0,
      1.0,
    );
    return Curves.easeOut.transform(opacity);
  }

  _FallbackCollapseState _collapseStateForIndex({
    required int index,
    required int totalHabits,
    required bool hasFallbackCandidate,
    required double normalizedPrimaryProgress,
  }) {
    if (!hasFallbackCandidate || index < widget.fallbackVisibleHabits) {
      return const _FallbackCollapseState(visible: true, opacity: 1);
    }

    final extraCount = (totalHabits - widget.fallbackVisibleHabits).clamp(
      0,
      totalHabits,
    );
    if (extraCount <= 0) {
      return const _FallbackCollapseState(visible: true, opacity: 1);
    }

    final collapseWindowMs = (widget.reorderDurationMs *
            widget.reorderSwapPoint)
        .round()
        .clamp(1, widget.reorderDurationMs);

    final adaptiveFadeMs = (collapseWindowMs / extraCount).clamp(
      1,
      _collapseBaseFadeDurationMs.toDouble(),
    );

    final bottomMostExtraIndex = totalHabits - 1;
    final extraOrderFromBottom = (bottomMostExtraIndex - index).clamp(
      0,
      extraCount,
    );

    final startMs = extraOrderFromBottom * adaptiveFadeMs;
    final endMs = startMs + adaptiveFadeMs;
    final elapsedMs = normalizedPrimaryProgress * collapseWindowMs;

    if (elapsedMs >= endMs) {
      return const _FallbackCollapseState(visible: false, opacity: 0);
    }

    if (elapsedMs <= startMs) {
      return const _FallbackCollapseState(visible: true, opacity: 1);
    }

    final fadeT = ((elapsedMs - startMs) / adaptiveFadeMs).clamp(0.0, 1.0);
    final opacity = 1 - Curves.easeOut.transform(fadeT);
    return _FallbackCollapseState(visible: true, opacity: opacity);
  }

  @override
  void initState() {
    super.initState();
    _extraRevealController =
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: _maxExtraRevealDurationMs),
          )
          ..addListener(() {
            if (mounted) {
              setState(() {});
            }
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() {
                _isRevealingExtras = false;
              });
            }
          });
  }

  @override
  void didUpdateWidget(covariant NewHabitCategory oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.reorderActive) {
      if (_isRevealingExtras || _extraRevealController.isAnimating) {
        _extraRevealController.stop();
        if (_isRevealingExtras && mounted) {
          setState(() {
            _isRevealingExtras = false;
          });
        }
      }
      return;
    }

    final reorderJustFinished =
        oldWidget.reorderActive && !widget.reorderActive;
    final hadFallbackInReorder = oldWidget.useFallbackAnimation;
    final hasExtraHabitsNow = _extraHabitsCountForWidget(widget) > 0;

    if (reorderJustFinished && hadFallbackInReorder && hasExtraHabitsNow) {
      _startExtraReveal();
    }
  }

  @override
  void dispose() {
    _extraRevealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryHabits =
        widget.habits
            .where(
              (habit) =>
                  habit.categoryId == widget.category.id, // && !habit.optional,
            )
            .toList(); // It will not show additional habits/tasks

    final hasFallbackCandidate =
        widget.reorderActive &&
        widget.useFallbackAnimation &&
        categoryHabits.length > widget.fallbackVisibleHabits;

    final normalizedPrimaryProgress =
        widget.reorderActive && widget.reorderSwapPoint > 0
            ? (widget.reorderProgress / widget.reorderSwapPoint).clamp(0.0, 1.0)
            : 0.0;
    final disableInteractions = widget.reorderActive || _isRevealingExtras;

    return Column(
      spacing: 10,
      children: [
        // Using the new ScrollTransformedHabitCategoryTitle
        if (categoryHabits.isNotEmpty && widget.showTitle)
          NewHabitCategoryTitle(
            isFirst: widget.isFirst,
            category: widget.category,
          ),
        for (int index = 0; index < categoryHabits.length; index++)
          Opacity(
            key: ValueKey('habit-fade-${categoryHabits[index].id}'),
            opacity: () {
              final collapseState = _collapseStateForIndex(
                index: index,
                totalHabits: categoryHabits.length,
                hasFallbackCandidate: hasFallbackCandidate,
                normalizedPrimaryProgress: normalizedPrimaryProgress,
              );
              return (collapseState.opacity *
                      _extraRevealOpacityForIndex(index, categoryHabits.length))
                  .clamp(0.0, 1.0);
            }(),
            child: SizedBox(
              width: double.infinity,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 350),
                alignment: Alignment.topCenter,
                curve: Curves.easeInOut,
                child: () {
                  final collapseState = _collapseStateForIndex(
                    index: index,
                    totalHabits: categoryHabits.length,
                    hasFallbackCandidate: hasFallbackCandidate,
                    normalizedPrimaryProgress: normalizedPrimaryProgress,
                  );

                  if (!collapseState.visible) {
                    return const SizedBox.shrink();
                  }

                  return GestureDetector(
                    onTap: () {
                      if (disableInteractions) return;

                      final habit = categoryHabits[index];

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HabitDetailsPage(habitId: habit.id),
                        ),
                      );
                    },
                    child: IgnorePointer(
                      ignoring: disableInteractions,
                      child: NewHabitWidget(
                        key: ValueKey(categoryHabits[index].id),
                        habit: categoryHabits[index],
                      ),
                    ),
                  );
                }(),
              ),
            ),
          ),
        if (widget.showOptionalHabits) Container(),
        // additional tasks
      ],
    );
  }
}

class _FallbackCollapseState {
  final bool visible;
  final double opacity;

  const _FallbackCollapseState({required this.visible, required this.opacity});
}
