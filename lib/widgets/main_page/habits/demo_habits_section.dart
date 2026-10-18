import 'package:flutter/material.dart';
import 'package:habitt/demo/demo_habits.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/main_page/habits/habit_widget/new_habit_widget.dart';
import 'package:provider/provider.dart';

class DemoHabitsSection extends StatelessWidget {
  const DemoHabitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Demo mode", style: TextStyle(color: cp.greyText)),
          for (final habit in demoHabits)
            SizedBox(
              width: double.infinity,
              child: NewHabitWidget(
                key: ValueKey('demo-habit-${habit.id}'),
                habit: habit,
                isDemo: true,
              ),
            ),
        ],
      ),
    );
  }
}
