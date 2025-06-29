import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final double height;
  final double? width;
  final Widget? child;
  final double borderRadius;
  final double blur;
  final Color borderColor;
  final Gradient gradient;
  final Color? color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Alignment alignment;

  const GlassContainer({
    super.key,
    this.alignment = Alignment.center,
    this.height = 200,
    this.width,
    this.child,
    this.borderRadius = 15,
    this.blur = 10,
    this.borderColor = Colors.white24,
    this.padding,
    this.margin,
    this.gradient = const LinearGradient(
      colors: [Colors.white24, Colors.white10],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          alignment: alignment,
          children: [
            if (color != null)
              // Color overlay
              Container(
                height: height,
                width: width,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: child,
              ),

            // Blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(),
            ),

            // Gradient overlay
            Container(
              height: height,
              width: width,
              padding: padding,
              decoration: BoxDecoration(
                gradient: gradient,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
