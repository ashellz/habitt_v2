import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/main_page/habits/new_habit_category.dart';
import 'package:provider/provider.dart';

class NewHabits extends StatefulWidget {
  final DateTime? daySelected;
  final bool hasMainCategory;

  const NewHabits({super.key, this.daySelected, this.hasMainCategory = false});

  @override
  State<NewHabits> createState() => _NewHabitsState();
}

class _NewHabitsState extends State<NewHabits>
    with SingleTickerProviderStateMixin {
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
    final selectedCategoryId = categoryProvider.selectedCategoryId;

    final additionalTasksCount =
        habits.where((habit) => habit.additional).length;
    final cp = context.watch<ColorProvider>();

    final habitsListHeight = MediaQuery.of(context).size.height / 2;

    if (habits.isEmpty) {
      return SizedBox(
        height: habitsListHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 16,
          children: [
            SvgPicture.asset("assets/images/new-svg/empty-box.svg"),
            Text(
              "You haven’t added any habits yet",
              style: TextStyle(color: cp.lightGreyText, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (selectedCategoryId != 0) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: NewHabitCategory(
              isToday: widget.daySelected == null,
              habits: habits,
              showAdditionalTasks: true,
              category: categoryProvider.categories.firstWhere(
                (c) => c.id == selectedCategoryId,
              ),
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
            /*
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
                        child: NewHabitCategory(
                          isToday: widget.daySelected == null,
                          showAdditionalTasks: false,
                          isFirst: true,
                          category: category,
                          habits: habits,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
             */
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: NewHabitCategory(
                isToday: widget.daySelected == null,
                habits: habits,
                category: category,
                showAdditionalTasks: false,
              ),
            ),

        Padding(
          padding: EdgeInsets.only(
            top: additionalTasksCount == habits.length ? 12 : 0,
          ),
          // child additional tasks
        ),
      ],
    );
  }
}
