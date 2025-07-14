import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/habits_page/additional_tasks/additional_tasks.dart';
import 'package:habitt/widgets/habits_page/habit_category.dart';
import 'package:habitt/widgets/pulse_animation.dart';
import 'package:provider/provider.dart';

class Habits extends StatefulWidget {
  final ScrollController scrollController;
  final double bottomViewportEdgeGlobalY;
  final double effectZoneHeight;
  final double minScale;
  final double stackOffsetFactor;
  final bool hasMainCategory;
  final DateTime? daySelected;

  const Habits({
    super.key,
    required this.scrollController,
    required this.bottomViewportEdgeGlobalY,
    required this.effectZoneHeight,
    required this.minScale,
    required this.stackOffsetFactor,
    this.hasMainCategory = true,
    this.daySelected,
  });

  @override
  State<Habits> createState() => _HabitsState();
}

class _HabitsState extends State<Habits> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  List<Habit> _getHabits() {
    final habitProvider = context.watch<HabitProvider>();

    if (widget.daySelected == null) {
      return habitProvider.habits;
    }

    return habitProvider.getHabitsFromDay(widget.daySelected!);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    final habits = _getHabits();
    final ColorProvider colorProvider = context.watch<ColorProvider>();

    if (habits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0, left: 16, right: 16),
        child: Text(
          "No habits yet.",
          style: TextStyle(color: colorProvider.mutedTextColor),
        ),
      );
    }

    if (categoryProvider.selectedCategoryId != 0) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: HabitCategory(
              isToday: widget.daySelected == null,
              habits: habits,
              showAdditionalTasks: true,
              category: categoryProvider.categories.firstWhere(
                (c) => c.id == categoryProvider.selectedCategoryId,
              ),
              // Pass parameters
              scrollController: widget.scrollController,
              bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
              effectZoneHeight: widget.effectZoneHeight,
              minScale: widget.minScale,
              stackOffsetFactor: widget.stackOffsetFactor,
            ),
          ),
        ],
      );
    }

    final List<Category> categories =
        widget.hasMainCategory
            ? categoryProvider.categoriesOrdered
            : categoryProvider.categories;

    return Column(
      children: [
        for (final category in categories)
          if (getCategoryLength(category, context, false) > 0)
            // Check if category is first
            if (category == categories.first && widget.hasMainCategory)
              // Put it in a glass box with animated gradient
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: colorProvider.colorScheme.standardColor.withAlpha(
                      255,
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: PulseAnimation(
                          _animation.value,
                          colorProvider,
                        ),
                        child: HabitCategory(
                          isToday: widget.daySelected == null,
                          showAdditionalTasks: false,
                          isFirst: true,
                          category: category,
                          habits: habits,
                          scrollController: widget.scrollController,
                          bottomViewportEdgeGlobalY:
                              widget.bottomViewportEdgeGlobalY,
                          effectZoneHeight: widget.effectZoneHeight,
                          minScale: widget.minScale,
                          stackOffsetFactor: widget.stackOffsetFactor,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: HabitCategory(
                  isToday: widget.daySelected == null,
                  habits: habits,
                  category: category,
                  showAdditionalTasks: false,
                  scrollController: widget.scrollController,
                  bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
                  effectZoneHeight: widget.effectZoneHeight,
                  minScale: widget.minScale,
                  stackOffsetFactor: widget.stackOffsetFactor,
                ),
              ),
        AdditionalTasks(
          isToday: widget.daySelected == null,
          scrollController: widget.scrollController,
          bottomViewportEdgeGlobalY: widget.bottomViewportEdgeGlobalY,
          effectZoneHeight: widget.effectZoneHeight,
          minScale: widget.minScale,
          stackOffsetFactor: widget.stackOffsetFactor,
        ),
      ],
    );
  }
}
