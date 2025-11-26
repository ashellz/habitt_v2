import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:provider/provider.dart';

class GlassBlurContainer extends StatelessWidget {
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
  final bool fakeBlur;
  final Border? border;

  const GlassBlurContainer({
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
      colors: [
        Color.fromARGB(33, 255, 255, 255),
        Color.fromARGB(12, 255, 255, 255),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.color,
    this.fakeBlur = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final prefsProvider = context.watch<PreferencesProvider>();

    final isGlassFeel = prefsProvider.glassFeel;

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

                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: child,
              ),

            // Blur effect
            if (!fakeBlur && isGlassFeel)
              SizedBox(
                height: height,
                width: width,
                child: BackdropFilter(
                  enabled: true,
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(),
                ),
              ),

            // Gradient overlay
            Container(
              height: height,
              width: width,
              padding: padding,
              decoration: BoxDecoration(
                gradient: !isGlassFeel ? null : gradient,
                border: border ?? Border.all(color: borderColor),
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
