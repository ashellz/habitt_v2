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

class _NewHabitCategoryState extends State<NewHabitCategory> {
  double _opacity = 0; // For initial fade-in

  @override
  void initState() {
    super.initState();
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
              opacity: contentOpacity,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 120),
                alignment: Alignment.topCenter,
                curve: Curves.easeInOut,
                child:
                    index >= firstCollapsedIndex
                        ? const SizedBox.shrink()
                        : GestureDetector(
                          onTap: () {
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
                          child: NewHabitWidget(
                            key: ValueKey(categoryHabits[index].id),
                            habit: categoryHabits[index],
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
