import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/services/new_color_service.dart';

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
            child: Center(
              child: Text(habit.iconPath, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ),
    );
  }
}
