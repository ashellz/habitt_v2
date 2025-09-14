import 'package:flutter/widgets.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/widgets/habits_page/additional_tasks/additional_tasks.dart';
import 'package:habitt/widgets/habits_page/scroll_transformed_habit_category_title.dart';
import 'package:habitt/widgets/scroll_transformed_habit_widget.dart';

class HabitCategory extends StatefulWidget {
  const HabitCategory({
    super.key,
    this.isFirst = false,
    required this.showAdditionalTasks,
    required this.category,
    required this.scrollController,
    required this.bottomViewportEdgeGlobalY,
    required this.effectZoneHeight,
    required this.minScale,
    required this.stackOffsetFactor,
    required this.habits,
    required this.isToday,
  });

  final bool isFirst;
  final Category category;
  final bool showAdditionalTasks;
  // These parameters are passed down from HabitsPage -> Habits -> HabitCategory
  final ScrollController scrollController;
  final double bottomViewportEdgeGlobalY;
  final double effectZoneHeight;
  final double minScale;
  final double stackOffsetFactor;
  final List<Habit> habits;
  final bool isToday;

  @override
  State<HabitCategory> createState() => _HabitCategoryState();
}

class _HabitCategoryState extends State<HabitCategory> {
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
                  habit.categoryId == widget.category.id && !habit.additional,
            )
            .toList(); // It will not show additional habits/tasks

    return AnimatedOpacity(
      opacity: _opacity, // For the initial fade-in of the whole category block
      duration: const Duration(milliseconds: 150),
      child: Column(
        children: [
          // Using the new ScrollTransformedHabitCategoryTitle
          if (categoryHabits.isNotEmpty)
            ScrollTransformedHabitCategoryTitle(
              isFirst: widget.isFirst,
              category: widget.category,
              countAdditionalTasks: false,
              scrollController: widget.scrollController,
              bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
              effectZoneHeight: widget.effectZoneHeight,
              minScale: widget.minScale,
              stackOffsetFactor: widget.stackOffsetFactor,
            ),
          for (final habit in categoryHabits)
            ScrollTransformedHabitWidget(
              isToday: widget.isToday,
              habit: habit,
              isFirstCategory: widget.isFirst,
              editable: false,
              scrollController: widget.scrollController,
              bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
              effectZoneHeight: widget.effectZoneHeight,
              minScale: widget.minScale,
              stackOffsetFactor: widget.stackOffsetFactor,
            ),
          if (widget.showAdditionalTasks)
            AdditionalTasks(
              habits: widget.habits,
              isToday: widget.isToday,
              hasHabits: categoryHabits.isNotEmpty,
              category: widget.category,
              scrollController: widget.scrollController,
              bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
              effectZoneHeight: widget.effectZoneHeight,
              minScale: widget.minScale,
              stackOffsetFactor: widget.stackOffsetFactor,
            ),
        ],
      ),
    );
  }
}
