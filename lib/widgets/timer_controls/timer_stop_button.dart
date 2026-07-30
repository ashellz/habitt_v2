import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class TimerStopButton extends StatefulWidget {
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
  State<TimerStopButton> createState() => _TimerStopButtonState();
}

class _TimerStopButtonState extends State<TimerStopButton> {
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
        widget.onTap?.call();
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
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.4,
        child: Container(
          height: widget.size,
          width: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cp.error.withValues(alpha: 0.1),
          ),
          child: AnimatedScale(
            scale: widget.enabled ? _scale : 1,
            duration: const Duration(milliseconds: 150),
            child: Center(
              child: SvgPicture.asset(
                "assets/images/new-svg/stop-timer.svg",
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
