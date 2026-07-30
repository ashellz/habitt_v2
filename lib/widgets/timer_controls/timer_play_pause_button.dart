import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class TimerPlayPauseButton extends StatefulWidget {
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
  State<TimerPlayPauseButton> createState() => _TimerPlayPauseButtonState();
}

class _TimerPlayPauseButtonState extends State<TimerPlayPauseButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return GestureDetector(
      onTap: () {
        setState(() {
          _scale = 0.9;
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() {
            _scale = 1.0;
          });
        });
        widget.onTap.call();
      },

      onTapDown: (context) {
        HapticFeedback.selectionClick();
        setState(() {
          _scale = 0.9;
        });
      },
      onTapCancel: () {
        setState(() {
          _scale = 1.0;
        });
      },
      onTapUp: (context) {
        HapticFeedback.selectionClick();
        setState(() {
          _scale = 1.0;
        });
      },
      child: Container(
        height: widget.size,
        width: widget.size,
        padding: EdgeInsets.all(widget.outerPadding),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cp.main.withValues(alpha: 0.2),
        ),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: const Alignment(0.09, 0.11),
                end: const Alignment(0.86, 0.90),
                colors: [cp.mainButtonLeftGradient, cp.mainButtonRightGradient],
              ),
            ),
            padding: EdgeInsets.all(widget.innerPadding),
            child: Center(
              child: SvgPicture.asset(
                widget.isRunning
                    ? "assets/images/new-svg/pause-timer.svg"
                    : "assets/images/new-svg/start-timer.svg",
                width: widget.iconSize,
                height: widget.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
