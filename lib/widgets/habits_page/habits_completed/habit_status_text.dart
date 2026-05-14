import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class HabitsStatus extends StatelessWidget {
  const HabitsStatus({
    super.key,
    required this.isCompleted,
    required this.numberOfHabits,
  });

  final bool isCompleted;
  final int numberOfHabits;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final textColor = tp.primaryTextColor;
    final loc = AppLocalizations.of(context)!;

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
                color: isCompleted ? tp.primaryColor : tp.mutedBgColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                isCompleted ? loc.completed : loc.notCompleted,
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
          "$numberOfHabits ${numberOfHabits == 1 ? loc.habit : loc.habits}",
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
