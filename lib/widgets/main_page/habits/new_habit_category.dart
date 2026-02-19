import 'package:flutter/material.dart';
import 'package:habitt/models/category.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/main_pages/main_page.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_widget.dart';

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
            NewHabitCategoryTitle(
              isFirst: widget.isFirst,
              category: widget.category,
            ),
          for (final habit in categoryHabits) NewHabitWidget(habit: habit),
          if (widget.showAdditionalTasks) Container(),
          // additional tasks
        ],
      ),
    );
  }
}
