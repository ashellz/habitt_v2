import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: Image.asset(
            "assets/images/gradient_background.png",
            color: colorProvider.colorScheme.vividColor,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        child,
      ],
    );
  }
}
