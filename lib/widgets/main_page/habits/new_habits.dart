import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
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
  late List<Habit> habits;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    habits = _getHabits();
  }

  double _calculateHabitsListHeight(
    BuildContext context,
    int perfectDaysStreak,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const bottomNavBar = 178;

    final baseHeight =
        topPadding +
        20 +
        40 +
        79 +
        20 +
        (36 + 40) +
        bottomNavBar +
        bottomPadding;
    final baseHeightWithStreak =
        topPadding +
        20 +
        60 +
        79 +
        82 +
        20 +
        (36 + 40) +
        bottomNavBar +
        bottomPadding;

    final height = perfectDaysStreak > 0 ? baseHeightWithStreak : baseHeight;
    return MediaQuery.of(context).size.height - height;
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

    final optionalHabitsCount = habits.where((habit) => habit.optional).length;
    final cp = context.watch<ColorProvider>();

    final perfectDaysStreak = context.watch<StatsProvider>().perfectDaysStreak;
    final habitsListHeight = _calculateHabitsListHeight(
      context,
      perfectDaysStreak,
    );

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
              key: ValueKey(selectedCategoryId),
              isToday: widget.daySelected == null,
              habits: habits,
              showOptionalHabits: true,
              category: categoryProvider.categories.firstWhere(
                (c) => c.id == selectedCategoryId,
              ),
            ),
          ),
        ],
      );
    }

    final List<Category> categories = categoryProvider.categoriesOrdered;

    return Column(
      children: [
        for (final category in categories)
          if (getCategoryLength(category, context, false, widget.daySelected) >
              0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: NewHabitCategory(
                isToday: widget.daySelected == null,
                habits: habits,
                isFirst: category == categories.first,
                category: category,
                showOptionalHabits: false,
              ),
            ),

        Padding(
          padding: EdgeInsets.only(
            top: optionalHabitsCount == habits.length ? 12 : 0,
          ),
          // child additional tasks
        ),
      ],
    );
  }
}
