import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:inner_glow/inner_glow.dart';
import 'package:provider/provider.dart';

class GlassFeelContainer extends StatefulWidget {
  const GlassFeelContainer({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.all(0),
    this.padding = const EdgeInsets.all(12),
    this.height,
    this.isHabit = false,
    this.width,
  });

  final Widget child;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double? height;
  final double? width;
  final bool isHabit;

  @override
  State<GlassFeelContainer> createState() => _GlassFeelContainerState();
}

class _GlassFeelContainerState extends State<GlassFeelContainer> {
  final GlobalKey _containerKey = GlobalKey();
  double _height = 0;

  @override
  void initState() {
    super.initState();

    _height = widget.height ?? 0;
    // Wait for the first frame to get the size
    if (widget.height != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());
    }
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
    final tp = context.watch<ThemeProvider>();
    final prefsProvider = context.watch<PreferencesProvider>();

    if (!prefsProvider.glassFeel) {
      if (widget.isHabit) {
        return Container(
          padding: widget.padding,
          margin: widget.margin,

          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tp.borderColor, width: 2),
            color: tp.elevatedSurfaceColor,
          ),

          child: widget.child,
        );
      }
      return Container(
        padding: widget.padding,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: tp.surfaceColor,
          border: Border.all(color: tp.borderColor, width: 2),
        ),
        width: widget.width ?? double.infinity,
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
                Colors.white.withOpacity(tp.isDark ? 0.4 : 1),
                Colors.white.withOpacity(tp.isDark ? 0.05 : 0.2),
                Colors.white.withOpacity(tp.isDark ? 0.2 : 0.7),
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
            width: widget.width ?? double.infinity,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [tp.surfaceColor, tp.elevatedSurfaceColor],
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
              width: widget.width ?? double.infinity,
              height: _height,
              thickness: tp.isDark ? 1 : 10,
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
