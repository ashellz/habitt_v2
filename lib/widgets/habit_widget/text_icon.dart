import 'package:flutter/material.dart';

class TextIcon extends StatelessWidget {
  const TextIcon(this.text, {super.key, this.size = 24, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool isOld = text.contains("assets");

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            isOld ? "❌" : text,
            textAlign: TextAlign.center,
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            style: TextStyle(
              fontSize: size,
              height: 1,
              leadingDistribution: TextLeadingDistribution.even,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
