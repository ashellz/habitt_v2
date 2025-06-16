import 'package:flutter/widgets.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_widget/habit_desc.dart';
import 'package:habitt/widgets/habit_widget/habit_name.dart';

class HabitText extends StatelessWidget {
  const HabitText({
    super.key,
    required this.habit,
    required this.colorProvider,
    required this.alpha,
    required this.value,
  });

  final Habit habit;
  final ColorProvider colorProvider;
  final int alpha;
  final double value;

  @override
  Widget build(BuildContext context) {
    bool hasStreak = false;
    if (habit.streak > 0 || habit.completed) {
      hasStreak = true;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: SizedBox(
        width:
            MediaQuery.of(context).size.width -
            32 - // 32 padding
            100 - // 100 on the right
            70 -
            (hasStreak ? 35 : 0), // 70 on the left
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          height: habit.description.isEmpty ? 23 : 43,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HabitNameDisplay(
                text: habit.name,
                completed: habit.completed,
                skipped: habit.skipped,
                textColor:
                    Color.lerp(
                      colorProvider.textColor.withAlpha(alpha),
                      colorProvider.textColor,
                      value,
                    )!,
              ),

              HabitDescDisplay(habit: habit, colorProvider: colorProvider),
            ],
          ),
        ),
      ),
    );
  }
}
