import 'package:flutter/material.dart';

/// Small pill shown on a habit card: "Optional", "Paused", the next scheduled
/// day. [color] is used for both the text and the optional [icon].
class HabitTag extends StatelessWidget {
  const HabitTag({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.icon,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      curve: Curves.linear,
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: EdgeInsets.fromLTRB(icon == null ? 4 : 6, 0, 4, 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (icon != null) icon!,
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
