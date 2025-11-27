import 'package:flutter/widgets.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/theme_provider.dart';

class HabitDescDisplay extends StatelessWidget {
  const HabitDescDisplay({super.key, required this.habit, required this.tp});

  final Habit habit;
  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150),
      height: habit.description.isEmpty || habit.completed ? 0 : 20,
      child: Text(
        habit.completed ? "" : habit.description,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        maxLines: 1,
        style: TextStyle(fontSize: 14, color: tp.mutedTextColor),
      ),
    );
  }
}
