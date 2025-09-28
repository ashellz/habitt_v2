import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/glass_blur_container.dart';

class CircleButton extends StatefulWidget {
  const CircleButton({
    super.key,
    required this.colorProvider,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  final ColorProvider colorProvider;
  final Widget icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  State<CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          scale = 0.9;
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() {
            scale = 1.0;
          });
        });

        if (widget.onPressed != null) {
          widget.onPressed!();
        }
      },
      onTapDown: (context) {
        setState(() {
          scale = 0.9;
        });
      },

      onTapCancel: () {
        setState(() {
          scale = 1.0;
        });
      },
      onTapUp: (context) {
        setState(() {
          scale = 1.0;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: scale,
        child: GlassBlurContainer(
          height: 50,
          width: 50,
          color: widget.color,
          borderRadius: 100,
          padding: const EdgeInsets.all(8),
          child: Center(child: widget.icon),
        ),
      ),
    );
  }
}
