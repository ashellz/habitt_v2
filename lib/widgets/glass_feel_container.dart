import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:inner_glow/inner_glow.dart';
import 'package:provider/provider.dart';

class GlassFeelContainer extends StatefulWidget {
  const GlassFeelContainer({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.all(0),
  });

  final Widget child;
  final EdgeInsets margin;

  @override
  State<GlassFeelContainer> createState() => _GlassFeelContainerState();
}

class _GlassFeelContainerState extends State<GlassFeelContainer> {
  final GlobalKey _containerKey = GlobalKey();
  double _height = 0;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame to get the size
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());
  }

  void _updateHeight() {
    final context = _containerKey.currentContext;
    if (context != null) {
      final newHeight = context.size?.height ?? 0;
      if (newHeight != _height) {
        setState(() {
          _height = newHeight;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final prefsProvider = context.watch<PreferencesProvider>();
    final colorScheme = colorProvider.colorScheme;

    if (!prefsProvider.glassFeel) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: colorScheme.standardColor,
          border: Border.all(color: colorScheme.strokeColor, width: 2),
        ),
        width: double.infinity,
        child: widget.child,
      );
    }

    return Stack(
      children: [
        Container(
          key: _containerKey,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),

            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(colorProvider.isDarkMode ? 0.4 : 1),
                Colors.white.withOpacity(colorProvider.isDarkMode ? 0.05 : 0.2),
                Colors.white.withOpacity(colorProvider.isDarkMode ? 0.2 : 0.7),
              ],
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 13,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          margin: widget.margin,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  colorProvider.colorScheme.standardColor,
                  colorProvider.habitColor,
                ],
              ),
              borderRadius: BorderRadius.circular(22.5),
            ),
            child: widget.child,
          ),
        ),

        Padding(
          padding: widget.margin,
          child: IgnorePointer(
            child: InnerGlow(
              width: double.infinity,
              height: _height,
              thickness: colorProvider.isDarkMode ? 1 : 10,
              glowBlur: 15,
              glowRadius: 25,
              baseDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
