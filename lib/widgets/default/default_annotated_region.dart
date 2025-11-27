import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class DefaultAnnotatedRegion extends StatelessWidget {
  const DefaultAnnotatedRegion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isDark = tp.isDark;
    final bg = isDark ? Colors.black : Colors.white;
    final statusBarIcons = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: bg,
        statusBarIconBrightness: statusBarIcons,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: child,
    );
  }
}
