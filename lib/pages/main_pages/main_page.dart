import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/main_page_top_section.dart';
import 'package:provider/provider.dart';

import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/get_category_length.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/habits_page/pulse_animation.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: cp.bg,
      body: ListView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MainPageTopSection(),
          ),
          SizedBox(height: 20),
          Container(
            color: cp.habitBg,
            child: Column(
              children: [
                NewCategoriesList(),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 138,
                  ),
                  child: NewHabits(hasMainCategory: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NewHabits extends StatefulWidget {
  final DateTime? daySelected;
  final bool hasMainCategory;

  const NewHabits({super.key, this.daySelected, required this.hasMainCategory});

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

class NewHabitCategory extends StatefulWidget {
  const NewHabitCategory({
    super.key,
    this.isFirst = false,
    required this.showAdditionalTasks,
    required this.category,
    required this.habits,
    required this.isToday,
  });

  final bool isFirst;
  final Category category;
  final bool showAdditionalTasks;
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
                  habit.categoryId == widget.category.id && !habit.additional,
            )
            .toList(); // It will not show additional habits/tasks

    return AnimatedOpacity(
      opacity: _opacity, // For the initial fade-in of the whole category block
      duration: const Duration(milliseconds: 150),
      child: Column(
        spacing: 10,
        children: [
          // Using the new ScrollTransformedHabitCategoryTitle
          if (categoryHabits.isNotEmpty)
            NewHabitCategoryTitleContent(
              category: widget.category,
              countAdditionalTasks: widget.showAdditionalTasks,
            ),
          for (final habit in categoryHabits) NewHabitWidget(),
          if (widget.showAdditionalTasks) Container(),
          // additional tasks
        ],
      ),
    );
  }
}

class NewHabitCategoryTitleContent extends StatelessWidget {
  const NewHabitCategoryTitleContent({
    super.key,
    required this.category,
    required this.countAdditionalTasks,
  });

  final Category category;
  final bool countAdditionalTasks;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    //    final int categoryHabits = getCategoryLength(
    //    category,
    //  context,
    //countAdditionalTasks,
    //);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(category.name, style: TextStyle(color: cp.greyText))],
    );
  }
}

class NewHabitWidget extends StatelessWidget {
  const NewHabitWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: cp.widget,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: cp.border),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              color: cp.habitIconBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
