import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habits_page/habits_completed/habit_status_text.dart';
import 'package:provider/provider.dart';

class HabitsCompletedWidget extends StatelessWidget {
  const HabitsCompletedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final colorScheme = colorProvider.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.standardColor,
          border: Border.all(color: colorScheme.strokeColor, width: 2),
        ),
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Column(
            children: [
              HabitsStatus(isCompleted: true),
              const SizedBox(height: 8),
              HabitsStatus(isCompleted: false),
            ],
          ),
        ),
      ),
    );
  }
}
