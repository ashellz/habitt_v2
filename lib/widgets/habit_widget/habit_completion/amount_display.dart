import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.habit,
    required this.colorProvider,
  });

  final Habit habit;
  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          habit.amountCompleted.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF8F9FA),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(height: 2, thickness: 2, color: Color(0xFFF8F9FA)),
        ),
        Text(
          habit.amount.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFF8F9FA),
          ),
        ),
      ],
    );
  }
}
