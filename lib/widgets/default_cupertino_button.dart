import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class DefaultCupertinoButton extends StatelessWidget {
  const DefaultCupertinoButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color,
    this.textColor,
  });

  final VoidCallback? onPressed;
  final String text;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return CupertinoButton(
      color: color ?? colorProvider.colorScheme.darkerStandardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: BorderRadius.circular(24),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? colorProvider.textColor,
          fontSize: 16,
        ),
      ),
    );
  }
}
