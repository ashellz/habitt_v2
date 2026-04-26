import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class ValueBlurCloud extends StatelessWidget {
  const ValueBlurCloud({
    super.key,
    required this.child,
    this.progress,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final double? progress;
  final BorderRadius borderRadius;

  double _opacityFor(double t) {
    if (t <= 0 || t >= 0.58) {
      return 0;
    }
    if (t < 0.16) {
      return (t / 0.16) * 0.85;
    }
    return (1 - ((t - 0.16) / 0.42)).clamp(0.0, 1.0) * 0.85;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final t = progress ?? 1;
    final opacity = _opacityFor(t);
    final sigma = 1 + (opacity * 5);

    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (opacity > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          cp.field.withValues(alpha: opacity * 0.95),
                          cp.field.withValues(alpha: opacity * 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.65, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
