import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_category_title.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_widget.dart';
import 'package:habitt/widgets/sheets/edit_habit_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class NewHabitCategory extends StatefulWidget {
  const NewHabitCategory({
    super.key,
    this.isFirst = false,
    this.reorderActive = false,
    this.reorderProgress = 0,
    this.reorderSwapPoint = 0.48,
    this.useFallbackAnimation = false,
    this.fallbackVisibleHabits = 3,
    required this.showOptionalHabits,
    required this.category,
    required this.habits,
    required this.isToday,
  });

  final bool isFirst;
  final bool reorderActive;
  final double reorderProgress;
  final double reorderSwapPoint;
  final bool useFallbackAnimation;
  final int fallbackVisibleHabits;
  final Category category;
  final bool showOptionalHabits;
  final List<Habit> habits;
  final bool isToday;

  @override
  State<NewHabitCategory> createState() => _NewHabitCategoryState();
}

class _NewHabitCategoryState extends State<NewHabitCategory>
    with SingleTickerProviderStateMixin {
  static const int _extraRevealBaseDelayMs = 350;
  static const int _extraRevealFadeDurationMs = 120;

  double _opacity = 0; // For initial fade-in
  late final AnimationController _extraRevealController;
  bool _isRevealingExtras = false;

  int get _maxExtraRevealDurationMs =>
      _extraRevealBaseDelayMs + _extraRevealFadeDurationMs;

  int _extraHabitsCountForWidget(NewHabitCategory widgetConfig) {
    final categoryHabits =
        widgetConfig.habits
            .where(
              (habit) =>
                  habit.categoryId == widgetConfig.category.id &&
                  !habit.optional,
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
    final delayMs =
        (_extraRevealBaseDelayMs - (extraOrderFromBottom * delayStep)).clamp(
      0,
      _extraRevealBaseDelayMs.toDouble(),
    );

    final elapsedMs = _extraRevealController.value * _maxExtraRevealDurationMs;
    final opacity = ((elapsedMs - delayMs) / _extraRevealFadeDurationMs).clamp(
      0.0,
      1.0,
    );
    return Curves.easeOut.transform(opacity);
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

    // Original fade-in animation
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() {
          _opacity = 1;
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
                  habit.categoryId == widget.category.id && !habit.optional,
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

    final contentFadeT =
        hasFallbackCandidate
            ? (normalizedPrimaryProgress / 0.35).clamp(0.0, 1.0)
            : 0.0;
    final collapseT =
        hasFallbackCandidate
            ? ((normalizedPrimaryProgress - 0.25) / 0.75).clamp(0.0, 1.0)
            : 0.0;

    final contentOpacity =
        hasFallbackCandidate
            ? (1 - (0.55 * Curves.easeOut.transform(contentFadeT))).clamp(
              0.0,
              1.0,
            )
            : 1.0;

    final extraHabits = categoryHabits.length - widget.fallbackVisibleHabits;
    final collapsedExtra =
        hasFallbackCandidate
            ? (extraHabits * Curves.easeInOut.transform(collapseT)).floor()
            : 0;
    final visibleCount =
        hasFallbackCandidate
            ? (categoryHabits.length - collapsedExtra).clamp(
              widget.fallbackVisibleHabits,
              categoryHabits.length,
            )
            : categoryHabits.length;

    final firstCollapsedIndex =
        hasFallbackCandidate ? visibleCount : categoryHabits.length;
    final disableInteractions = widget.reorderActive || _isRevealingExtras;

    return AnimatedOpacity(
      opacity: _opacity, // For the initial fade-in of the whole category block
      duration: const Duration(milliseconds: 150),
      child: Column(
        spacing: 10,
        children: [
          // Using the new ScrollTransformedHabitCategoryTitle
          if (categoryHabits.isNotEmpty)
            NewHabitCategoryTitle(
              isFirst: widget.isFirst,
              category: widget.category,
            ),
          for (int index = 0; index < categoryHabits.length; index++)
            AnimatedOpacity(
              key: ValueKey('habit-fade-${categoryHabits[index].id}'),
              duration: const Duration(milliseconds: 100),
              opacity:
                  contentOpacity *
                  _extraRevealOpacityForIndex(index, categoryHabits.length),
              child: SizedBox(
                width: double.infinity,
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  alignment: Alignment.topCenter,
                  curve: Curves.easeInOut,
                  child:
                      index >= firstCollapsedIndex
                          ? const SizedBox.shrink()
                          : GestureDetector(
                            onTap: () {
                              if (disableInteractions) return;

                              final cp = context.read<ColorProvider>();
                              final habit = categoryHabits[index];

                              showModalBottomSheet(
                                context: context,
                                backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
                                barrierColor: cp.greyText.darken().withOpacity(
                                  0.3,
                                ),
                                isScrollControlled: true,
                                builder: (context) => HabitSheet(habit: habit),
                              );
                            },
                            child: IgnorePointer(
                              ignoring: disableInteractions,
                              child: NewHabitWidget(
                                key: ValueKey(categoryHabits[index].id),
                                habit: categoryHabits[index],
                              ),
                            ),
                          ),
                ),
              ),
            ),
          if (widget.showOptionalHabits) Container(),
          // additional tasks
        ],
      ),
    );
  }
}
