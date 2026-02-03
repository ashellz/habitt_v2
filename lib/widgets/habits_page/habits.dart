import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/habits_page/additional_tasks/additional_tasks.dart';
import 'package:habitt/widgets/habits_page/habit_category.dart';
import 'package:habitt/widgets/habits_page/pulse_animation.dart';
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
  late List<Habit> habits;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    habits = _getHabits();
  }

  List<Habit> _getHabits() {
    debugPrint(
      "Getting habits for Habits widget ======================================== new DAY SELECTED: ${widget.daySelected} ",
    );
    final habitProvider = context.read<HabitProvider>();
    final today = DateTime.now();
    final todayShort = DateTime(today.year, today.month, today.day);
    if (widget.daySelected == null || widget.daySelected == todayShort) {
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
    final calendarProvider = context.watch<CalendarProvider>();
    final selectedCategoryId =
        widget.daySelected == null
            ? categoryProvider.selectedCategoryId
            : calendarProvider.selectedCategoryId;

    final additionalTasksCount =
        habits.where((habit) => habit.additional).length;
    final tp = context.watch<ThemeProvider>();

    if (habits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0, left: 16, right: 16),
        child: Text(
          "No habits yet.",
          style: TextStyle(color: tp.mutedTextColor),
        ),
      );
    }

    if (selectedCategoryId != 0) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: HabitCategory(
              isToday: widget.daySelected == null,
              habits: habits,
              showAdditionalTasks: true,
              category: categoryProvider.categories.firstWhere(
                (c) => c.id == selectedCategoryId,
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
          if (getCategoryLength(category, context, false, widget.daySelected) >
              0)
            // Check if category is first
            if (category == categories.first && widget.hasMainCategory)
              // Put it in a glass box with animated gradient
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GlassFeelContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: PulseAnimation(_animation.value, tp),
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
        Padding(
          padding: EdgeInsets.only(
            top: additionalTasksCount == habits.length ? 12 : 0,
          ),
          child: AdditionalTasks(
            isToday: widget.daySelected == null,
            habits: habits,
            hasHabits: additionalTasksCount != habits.length,
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
}
