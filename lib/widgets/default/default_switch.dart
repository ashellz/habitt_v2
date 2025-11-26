import 'package:flutter/material.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class DefaultSwitch extends StatelessWidget {
  const DefaultSwitch({
    super.key,
    required this.onTap,
    required this.switchValue,
  });

  final VoidCallback onTap;
  final bool switchValue;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isTinted =
        context.watch<PreferencesProvider>().colorfulness ==
        Colorfulness.tinted;

    return Switch(
      activeTrackColor: isTinted ? tp.primaryColor : tp.successColor,
      activeThumbColor: Colors.white,
      inactiveThumbColor: tp.primaryTextColor,
      inactiveTrackColor: tp.surfaceColor,
      value: switchValue,
      onChanged: (value) {
        onTap();
      },
    );
  }
}
