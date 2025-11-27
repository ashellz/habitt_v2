import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/theme_provider.dart';

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({super.key, required this.habit, required this.tp});

  final Habit habit;
  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyle(
      shadows: [
        Shadow(
          color: Colors.black.withAlpha(100),
          offset: const Offset(0, 1),
          blurRadius: 5,
        ),
      ],
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(habit.amountCompleted.toString(), style: textStyle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(height: 2, thickness: 2, color: Color(0xFFF8F9FA)),
        ),
        Text(habit.amount.toString(), style: textStyle),
      ],
    );
  }
}
