import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return SizedBox.expand(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  colorProvider.colorScheme.standardColor,
                  colorProvider.backgroundColor,
                  colorProvider.backgroundColor,
                  colorProvider.colorScheme.standardColor,
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
