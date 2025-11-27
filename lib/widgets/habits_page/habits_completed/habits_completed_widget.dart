import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:habitt/widgets/habits_page/habits_completed/habit_status_text.dart';

class HabitsCompletedWidget extends StatelessWidget {
  const HabitsCompletedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: GlassFeelContainer(
        child: Column(
          children: [
            HabitsStatus(isCompleted: true),
            const SizedBox(height: 8),
            HabitsStatus(isCompleted: false),
          ],
        ),
      ),
    );
  }
}
