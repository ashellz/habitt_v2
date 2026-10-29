import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

/// A soft round gradient behind a What's new graphic. [alignment] may go past
/// ±1 to push the blob partly out of the frame, where it is clipped.
class WhatsNewGlow {
  const WhatsNewGlow({
    required this.color,
    required this.alignment,
    this.size = 220,
    this.strength = 0.4,
  });

  final Color color;
  final Alignment alignment;
  final double size;
  final double strength;
}

/// Surface colours for the graphics: the frame sits on the dialog card, and the
/// tiles on the frame, so each steps one shade away from what is behind it.
extension WhatsNewColors on ColorProvider {
  Color get graphicBg => isDark ? field : habitBg;
  Color get graphicCard => isDark ? habitBg : bg;
}

/// The rounded box every What's new graphic is drawn in.
class WhatsNewGraphicFrame extends StatelessWidget {
  const WhatsNewGraphicFrame({
    super.key,
    required this.child,
    this.glows = const [],
  });

  final Widget child;
  final List<WhatsNewGlow> glows;

  static const double height = 244;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cp.graphicBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cp.border, width: 1),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Glows ────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final bounds = Offset.zero & constraints.biggest;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final glow in glows)
                    Positioned.fromRect(
                      rect: glow.alignment.inscribe(
                        Size.square(glow.size),
                        bounds,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              glow.color.withValues(
                                alpha: glow.strength * (cp.isDark ? 1 : 0.8),
                              ),
                              glow.color.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // ─── Graphic ──────────────────────────────────────
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
