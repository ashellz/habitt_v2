import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/habit_widget/new_habit_icon.dart';

import 'package:provider/provider.dart';

class NewHabitWidget extends StatelessWidget {
  const NewHabitWidget({super.key, required this.habit});

  final Habit habit;

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
      child: Row(children: [NewHabitIcon(iconPath: habit.iconPath)]),
    );
  }
}
