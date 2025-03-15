import 'package:flutter/material.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:provider/provider.dart';

class HabitsStatus extends StatelessWidget {
  const HabitsStatus({super.key, required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final textColor = colorProvider.textColor;
    final colorScheme = colorProvider.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    final habitsProvider = context.watch<HabitProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    const numberOfHabits = 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isCompleted
                        ? colorScheme.vividColor
                        : colorScheme.strokeColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                isCompleted
                    ? localizations.completed
                    : localizations.notCompleted,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        Text(
          "$numberOfHabits ${numberOfHabits == 1 ? localizations.habit : localizations.habits}",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
