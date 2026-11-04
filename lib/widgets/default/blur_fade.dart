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
/// once it is true. Starts blurred so the first appearance fades in, unless
/// [skipInitialFade] is set and it is already [ready].
class AnimatedBlurFade extends StatefulWidget {
  const AnimatedBlurFade({
    super.key,
    required this.ready,
    required this.child,
    this.minOpacity = 0,
    this.duration = const Duration(milliseconds: 350),
    this.skipInitialFade = false,
    this.replayToken,
  });

  final bool ready;
  final Widget child;
  final double minOpacity;
  final Duration duration;

  /// Starts sharp when [ready] is already true on the first build, for content
  /// restored from a cache that the user has seen before.
  final bool skipInitialFade;

  /// Changing this while [ready] replays the fade in from blurred, for content
  /// whose data changed under it. The child keeps its state.
  final Object? replayToken;

  @override
  State<AnimatedBlurFade> createState() => _AnimatedBlurFadeState();
}

class _AnimatedBlurFadeState extends State<AnimatedBlurFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.ready && widget.skipInitialFade ? 1 : 0,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.ready) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBlurFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;

    if (widget.ready && widget.replayToken != oldWidget.replayToken) {
      _controller.forward(from: 0);
    } else if (widget.ready != oldWidget.ready) {
      widget.ready ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder:
          (context, child) => BlurFade(
            progress: _progress.value,
            minOpacity: widget.minOpacity,
            child: child!,
          ),
    );
  }
}
