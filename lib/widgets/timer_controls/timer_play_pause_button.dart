import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class TimerPlayPauseButton extends StatelessWidget {
  const TimerPlayPauseButton({
    super.key,
    required this.isRunning,
    required this.onTap,
    this.size = 40,
    this.outerPadding = 4,
    this.innerPadding = 8,
    this.iconSize = 18,
  });

  final bool isRunning;
  final VoidCallback onTap;
  final double size;
  final double outerPadding;
  final double innerPadding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        padding: EdgeInsets.all(outerPadding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cp.main.withValues(alpha: 0.2),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: const Alignment(0.09, 0.11),
              end: const Alignment(0.86, 0.90),
              colors: [cp.mainButtonLeftGradient, cp.mainButtonRightGradient],
            ),
          ),
          padding: EdgeInsets.all(innerPadding),
          child: Center(
            child: SvgPicture.asset(
              isRunning
                  ? "assets/images/new-svg/pause-timer.svg"
                  : "assets/images/new-svg/start-timer.svg",
              width: iconSize,
              height: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
