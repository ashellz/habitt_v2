import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class TimerStopButton extends StatelessWidget {
  const TimerStopButton({
    super.key,
    required this.onTap,
    this.enabled = true,
    this.size = 40,
    this.iconSize = 18,
  });

  final VoidCallback? onTap;
  final bool enabled;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cp.error.withValues(alpha: 0.1),
          ),
          child: Center(
            child: SvgPicture.asset(
              "assets/images/new-svg/stop-timer.svg",
              width: iconSize,
              height: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
