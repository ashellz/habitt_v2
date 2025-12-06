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

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: tp.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            tp.isDark ? Brightness.dark : Brightness.light, // for iOS
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            tp.isDark ? Brightness.light : Brightness.dark,
      ),
      child: child,
    );
  }
}
