import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/widgets/habits_page/additional_tasks/additional_tasks_divider.dart';
import 'package:habitt/widgets/scroll_transformed_habit_widget.dart';

class AdditionalTasks extends StatefulWidget {
  const AdditionalTasks({
    super.key,
    this.category,
    this.hasHabits,
    required this.habits,
    required this.scrollController,
    required this.bottomViewportEdgeGlobalY,
    required this.effectZoneHeight,
    required this.minScale,
    required this.stackOffsetFactor,
    required this.isToday,
  });

  final Category? category;
  final bool? hasHabits;
  final List habits;
  // These parameters are passed down from HabitsPage -> Habits -> AdditionalTasks
  final ScrollController scrollController;
  final double bottomViewportEdgeGlobalY;
  final double effectZoneHeight;
  final double minScale;
  final double stackOffsetFactor;
  final bool isToday;

  @override
  State<AdditionalTasks> createState() => _AdditionalTasksState();
}

class _AdditionalTasksState extends State<AdditionalTasks> {
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
    final additionalTasks =
        widget.habits
            .where(
              (habit) =>
                  habit.additional &&
                  (widget.category != null
                      ? habit.categoryId == widget.category!.id
                      : true),
            )
            .toList(); // It will show only additional habits/tasks

    if (additionalTasks.isEmpty) return Container();

    return AnimatedOpacity(
      opacity: _opacity, // For the initial fade-in of the whole category block
      duration: const Duration(milliseconds: 150),
      child: Column(
        children: [
          ScrollTransformedHabitCategoryDivider(
            hasHabits: widget.hasHabits,
            scrollController: widget.scrollController,
            bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
            effectZoneHeight: widget.effectZoneHeight,
            minScale: widget.minScale,
            stackOffsetFactor: widget.stackOffsetFactor,
          ),
          for (final habit in additionalTasks)
            ScrollTransformedHabitWidget(
              isToday: widget.isToday,
              // Assuming this is the widget from the previous answer
              isFirstCategory: false,
              habit: habit,
              editable: false, // Or your logic for this
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
