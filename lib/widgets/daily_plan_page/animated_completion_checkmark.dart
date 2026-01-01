import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

class AnimatedCompletionCheckmark extends StatefulWidget {
  const AnimatedCompletionCheckmark({super.key, required this.size});

  final double size;

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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

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
                sigmaX: (1 - _controller.value) * 3,
                sigmaY: (1 - _controller.value) * 3,
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
