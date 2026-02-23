import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/habit_widget/new_habit_icon.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/main_habit_info.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_progress.dart';

import 'package:provider/provider.dart';

class NewHabitWidget extends StatelessWidget {
  const NewHabitWidget({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      decoration: ShapeDecoration(
        color: habit.completed ? cp.main.withOpacity(0.1) : cp.widget,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: habit.completed ? cp.main.withOpacity(0.2) : cp.border,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        spacing: 16,
        children: [
          NewHabitIcon(iconPath: habit.iconPath, isCompleted: habit.completed),
          Expanded(child: MainHabitInfo(habit: habit, cp: cp)),
          NewHabitProgress(habit: habit),
        ],
      ),
    );
  }
}
