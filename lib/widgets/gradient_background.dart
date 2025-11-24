import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return SizedBox.expand(
      child: Stack(
        children: [
          /*
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  tp.primaryColor.withAlpha(25),
                  tp.backgroundColor,
                  tp.backgroundColor,
                  tp.primaryColor.withAlpha(25),
                ],
              ),
            ),
          ),*/
          child,
        ],
      ),
    );
  }
}
