import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AnimatedCompletionCheckmark extends StatefulWidget {
  const AnimatedCompletionCheckmark({
    super.key,
    required this.size,
    this.duration = const Duration(milliseconds: 800),
  });

  final double size;
  final Duration duration;

  @override
  State<AnimatedCompletionCheckmark> createState() =>
      _AnimatedCompletionCheckmarkState();
}

class _AnimatedCompletionCheckmarkState
    extends State<AnimatedCompletionCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159, // 360 degrees
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: (1 - _controller.value) * 2,
                sigmaY: (1 - _controller.value) * 2,
              ),
              child: SvgPicture.asset(
                "assets/images/svg/check.svg",
                width: widget.size,
                height: widget.size,
              ),
            ),
          ),
        );
      },
    );
  }
}
