import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/other_pages/icons_page.dart';
import 'package:habitt/providers/color_provider.dart';

class HabitIcon extends StatelessWidget {
  const HabitIcon({
    super.key,
    required this.editable,
    required this.colorProvider,
    required this.alpha,
    required this.habit,

    required this.value,
  });

  final bool editable;
  final ColorProvider colorProvider;
  final int alpha;
  final Habit habit;
  // If habit is completed, opacity value from animation builder
  final double value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashFactory: NoSplash.splashFactory,
      enableFeedback: false,
      onTap: () {
        if (editable) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => IconsPage()));
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
                colorProvider.iconBackgroundColor.withAlpha(alpha),
                colorProvider.iconBackgroundColor,
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
            opacity: habit.completed ? 0.5 : 1,
            child: Image.asset(habit.iconPath),
          ),
        ),
      ),
    );
  }
}
