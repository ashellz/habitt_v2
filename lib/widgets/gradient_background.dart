import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          "assets/images/gradient_background.png",
          fit: BoxFit.cover,
          width: double.infinity,
        ),
        child,
      ],
    );
  }
}
