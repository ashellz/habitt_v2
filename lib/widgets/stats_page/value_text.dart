import 'package:flutter/material.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ValueText extends StatelessWidget {
  const ValueText({super.key, required this.text, required this.value});

  final String text;
  final int value;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final prefsProvider = context.watch<PreferencesProvider>();
    final colorfulness = prefsProvider.colorfulness;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 22,
              color: tp.primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: value.toString(),
            style: TextStyle(
              fontSize: 22,
              color:
                  colorfulness == Colorfulness.tinted
                      ? tp.primaryColor
                      : tp.successColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
