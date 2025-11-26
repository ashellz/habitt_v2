import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // final tp = context.watch<ThemeProvider>();

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
