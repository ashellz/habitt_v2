import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class StrengthRing extends StatefulWidget {
  const StrengthRing({super.key, required this.strength});

  final double strength;

  @override
  State<StrengthRing> createState() => _StrengthRingState();
}

class _StrengthRingState extends State<StrengthRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late double _currentStrength;

  @override
  void initState() {
    super.initState();
    _currentStrength = widget.strength.clamp(0.0, 1.0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = AlwaysStoppedAnimation(_currentStrength);
  }

  @override
  void didUpdateWidget(covariant StrengthRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextStrength = widget.strength.clamp(0.0, 1.0);
    if (nextStrength == _currentStrength) {
      return;
    }

    _animation = Tween<double>(
      begin: _currentStrength,
      end: nextStrength,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _currentStrength = nextStrength;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return SizedBox(
      width: 82,
      height: 82,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final animatedStrength = _animation.value;
          final percent = (animatedStrength * 100).round();

          final loc = AppLocalizations.of(context)!;

          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 82,
                height: 82,
                child: CircularProgressIndicator(
                  value: animatedStrength,
                  strokeWidth: 6,
                  backgroundColor: cp.habitBg,
                  valueColor: AlwaysStoppedAnimation(cp.text),
                ),
              ),
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: cp.habitBg,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RingValueBlurCloud(
                      progress: _controller.value,
                      borderRadius: BorderRadius.circular(8),
                      child: Text(
                        '$percent%',
                        style: TextStyle(
                          color: cp.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      loc.strength,
                      style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingValueBlurCloud extends StatelessWidget {
  const _RingValueBlurCloud({
    required this.child,
    required this.progress,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final double progress;
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
    final opacity = _opacityFor(progress);
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
