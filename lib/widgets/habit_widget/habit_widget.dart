import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/edit_habit_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_widget/habit_completion/habit_completion.dart';
import 'package:habitt/widgets/habit_widget/habit_icon.dart';
import 'package:habitt/widgets/habit_widget/habit_streak.dart';
import 'package:habitt/widgets/habit_widget/habit_text.dart';
import 'package:provider/provider.dart';

class HabitWidget extends StatelessWidget {
  const HabitWidget({super.key, required this.editable, required this.habit});

  final Habit habit;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final int alpha = 100;

    // Main container
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: habit.completed ? 0 : 1),
      duration: const Duration(milliseconds: 150),
      builder: (context, double value, child) {
        return GestureDetector(
          onTap:
              editable
                  ? null
                  : () {
                    // For navigating to edit habit page

                    final CategoryProvider categoryProvider =
                        context.read<CategoryProvider>();

                    // Save the selected category
                    final int temp = categoryProvider.selectedCategoryId;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditHabitPage(habit: habit),
                      ),
                    ).whenComplete(() {
                      // Select the saved category
                      categoryProvider.selectCategory(temp);
                    });
                  },
          child: Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            height: 74,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  Color.lerp(
                    colorProvider.habitColor.withAlpha(alpha),
                    colorProvider.habitColor,
                    value,
                  )!,
            ),
            // Inside of the container
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side
                Row(
                  children: [
                    // Icon circle container
                    HabitIcon(
                      editable: editable,
                      colorProvider: colorProvider,
                      alpha: alpha,
                      habit: habit,
                      value: value,
                    ),
                    // Text
                    HabitText(
                      habit: habit,
                      colorProvider: colorProvider,
                      alpha: alpha,
                      value: value,
                    ),
                  ],
                ),
                // Completion and streak
                Row(
                  children: [
                    if (habit.streak > 0)
                      StreakDisplay(
                        streak: habit.streak,
                        colorProvider: colorProvider,
                      ),
                    // Completion
                    CompletionDisplay(
                      editable: editable,
                      colorProvider: colorProvider,
                      habit: habit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
