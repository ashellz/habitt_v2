import 'package:flutter/material.dart';
import 'package:habitt/demo/demo_habits.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_widget/habit_card.dart';
import 'package:provider/provider.dart';

class DemoHabitsGrid extends StatelessWidget {
  const DemoHabitsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Demo mode",
            style: TextStyle(
              color: cp.lightGreyText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardSize = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final habit in demoHabits)
                    HabitCard(
                      key: ValueKey('demo-habit-card-${habit.id}'),
                      habit: habit,
                      cp: cp,
                      size: cardSize,
                      isDemo: true,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
