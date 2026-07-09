import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class PastDayHintDot extends StatelessWidget {
  const PastDayHintDot({super.key});

  static const double size = 10;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cp.error,
          shape: BoxShape.circle,
          border: Border.all(color: cp.bg, width: 1.5),
        ),
      ),
    );
  }
}
