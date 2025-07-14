import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';

class PulseAnimation extends CustomPainter {
  PulseAnimation(this.animationValue, this.colorProvider);

  final double animationValue;
  final ColorProvider colorProvider;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius =
        size.width * 0.9 * (0.8 + 0.2 * sin(animationValue * 2 * pi));

    final gradient = RadialGradient(
      colors: [
        colorProvider.colorScheme.vividColor.withOpacity(0.25),
        colorProvider.colorScheme.vividColor.withOpacity(0.06),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint =
        Paint()
          ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: radius),
          )
          ..blendMode = BlendMode.srcOver;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant PulseAnimation oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
