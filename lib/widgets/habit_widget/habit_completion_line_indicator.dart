import 'package:flutter/material.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/habit_widget/old_habit_widget.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

// DEPRACATED, LEGACY, NOT USED

class HabitCompletionLineIndicator extends StatelessWidget {
  const HabitCompletionLineIndicator({
    super.key,
    required this.widget,
    required this.tp,
  });

  final OldHabitWidget widget;
  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    Color getCompletionColor() {
      final habit = widget.habit;
      final colorfulness = context.watch<PreferencesProvider>().colorfulness;

      if (habit.skipped) {
        return tp.borderColor.darken(tp.isDark ? 0 : 45);
      }

      switch (colorfulness) {
        case Colorfulness.tinted:
          return tp.primaryColor;
        case Colorfulness.standard:
          return tp.successColor;
        case Colorfulness.colorful:
          return habit.resolveColor(tp) ?? tp.successColor;
      }
    }

    return Positioned(
      top: 28,
      left: widget.isFirstCategory ? 0 : 16,
      bottom: 20,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 2,
        margin: EdgeInsets.symmetric(
          vertical:
              widget.habit.completed || widget.habit.skipped
                  ? 0
                  : (40), // Initial size from the middle
        ),
        decoration: BoxDecoration(color: getCompletionColor()),
      ),
    );
  }
}
