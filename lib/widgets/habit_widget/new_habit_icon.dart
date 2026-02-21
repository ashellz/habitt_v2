import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/habit_widget/text_icon.dart';
import 'package:provider/provider.dart';

class NewHabitIcon extends StatelessWidget {
  const NewHabitIcon({
    super.key,
    required this.iconPath,
    required this.isCompleted,
  });

  final String iconPath;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: 42,
      height: 42,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: isCompleted ? cp.bg : cp.habitIconBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      padding: const EdgeInsets.all(9),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder:
            (child, animation) =>
                ScaleTransition(scale: animation, child: child),
        switchInCurve: Curves.decelerate,
        switchOutCurve: Curves.decelerate,
        child: AnimatedOpacity(
          key: ValueKey<String>(iconPath),
          duration: const Duration(milliseconds: 150),
          opacity: 1.0,
          child: Center(child: TextIcon(iconPath, size: 24)),
        ),
      ),
    );
  }
}
