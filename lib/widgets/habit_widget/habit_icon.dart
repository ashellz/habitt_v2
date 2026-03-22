import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_emoji_dialog.dart';
import 'package:provider/provider.dart';

class HabitIcon extends StatelessWidget {
  const HabitIcon({
    super.key,
    required this.editable,
    required this.tp,
    required this.alpha,
    required this.habit,
    required this.value,
  });

  final bool editable;
  final ThemeProvider tp;
  final int alpha;
  final Habit habit;
  // If habit is completed, opacity value from animation builder
  final double value;

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.read<StateProvider>();
    final cp = context.read<ColorProvider>();
    return InkWell(
      splashFactory: NoSplash.splashFactory,
      enableFeedback: false,
      onTap: () async {
        if (editable) {
          // Navigator.of(context).push(MaterialPageRoute(builder: (context) => EmojiPickerPage()));
          final emoji = await showEmojiKeyboardDialog(context, cp);
          if (emoji != null && context.mounted) {
            stateProvider.iconPath = emoji;
          }
        }
      },
      child: Container(
        width: 50,
        height: 50,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              Color.lerp(
                tp.surfaceColor.withAlpha(alpha),
                tp.surfaceColor,
                value,
              )!,
        ),
        // Icon
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder:
              (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
          switchInCurve: Curves.decelerate,
          switchOutCurve: Curves.decelerate,
          child: AnimatedOpacity(
            key: ValueKey<String>(habit.iconPath),
            duration: const Duration(milliseconds: 150),
            opacity: habit.completed || habit.skipped ? 0.5 : 1,
            child: Center(
              child: Text(habit.iconPath, style: const TextStyle(fontSize: 28)),
            ),
          ),
        ),
      ),
    );
  }
}
