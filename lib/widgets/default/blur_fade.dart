import 'dart:ui';

import 'package:flutter/material.dart';

/// Fades and blurs [child] by [progress]: 1 is sharp and fully visible, 0 is
/// blurred and at [minOpacity]. Used for loading states and content swaps.
class BlurFade extends StatelessWidget {
  const BlurFade({
    super.key,
    required this.progress,
    required this.child,
    this.minOpacity = 0,
    this.maxSigma = 8,
  });

  final double progress;
  final Widget child;
  final double minOpacity;
  final double maxSigma;

  /// An [AnimatedSwitcher] transition: the old child fades out into a blur
  /// while the new one fades in out of it.
  static Widget transition(Widget child, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder:
          (context, child) => BlurFade(progress: animation.value, child: child!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final sigma = (1 - t) * maxSigma;

    return Opacity(
      opacity: minOpacity + (1 - minOpacity) * t,
      child: ImageFiltered(
        enabled: sigma > 0.05,
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}

/// [BlurFade] that animates on its own: blurred while [ready] is false, sharp
/// once it is true. Starts blurred so the first appearance fades in.
class AnimatedBlurFade extends StatelessWidget {
  const AnimatedBlurFade({
    super.key,
    required this.ready,
    required this.child,
    this.minOpacity = 0,
    this.duration = const Duration(milliseconds: 350),
  });

  final bool ready;
  final Widget child;
  final double minOpacity;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ready ? 1 : 0),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder:
          (context, progress, child) => BlurFade(
            progress: progress,
            minOpacity: minOpacity,
            child: child!,
          ),
    );
  }
}
