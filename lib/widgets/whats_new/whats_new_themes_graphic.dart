import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/models/app_theme.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/theme_catalog.dart';
import 'package:habitt/widgets/whats_new/whats_new_graphic_frame.dart';
import 'package:provider/provider.dart';

/// A fan of small habit cards, each in another accent theme, the brand on top.
class WhatsNewThemesGraphic extends StatelessWidget {
  const WhatsNewThemesGraphic({super.key});

  // drawn back to front, so the last one is on top
  static const _fan = [
    (theme: ThemeCatalog.lagoon, dx: -132.0, dy: 22.0, angle: -0.34),
    (theme: ThemeCatalog.orchid, dx: 132.0, dy: 22.0, angle: 0.34),
    (theme: ThemeCatalog.ocean, dx: -66.0, dy: 6.0, angle: -0.17),
    (theme: ThemeCatalog.violet, dx: 66.0, dy: 6.0, angle: 0.17),
    (theme: ThemeCatalog.habitt, dx: 0.0, dy: -4.0, angle: 0.0),
  ];

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    Color accent(AppTheme theme) => theme.accent(isDark: cp.isDark).main;

    return WhatsNewGraphicFrame(
      glows: [
        WhatsNewGlow(
          color: accent(ThemeCatalog.ocean),
          alignment: const Alignment(-1.2, -1.3),
          size: 240,
        ),
        WhatsNewGlow(
          color: accent(ThemeCatalog.orchid),
          alignment: const Alignment(1.3, 1.2),
          size: 240,
        ),
        WhatsNewGlow(
          color: accent(ThemeCatalog.habitt),
          alignment: const Alignment(0, 0),
          size: 200,
          strength: 0.3,
        ),
      ],
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final card in _fan)
            Transform.translate(
              offset: Offset(card.dx, card.dy),
              child: Transform.rotate(
                angle: card.angle,
                child: _ThemeCard(
                  accent: accent(card.theme),
                  front: card.theme == ThemeCatalog.habitt,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.accent, required this.front});

  final Color accent;
  final bool front;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: 104,
      height: 138,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cp.graphicCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withValues(alpha: front ? 0.9 : 0.5),
          width: front ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (front ? accent : Colors.black).withValues(
              alpha: front ? 0.35 : (cp.isDark ? 0.4 : 0.1),
            ),
            blurRadius: front ? 24 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: SvgPicture.asset(
              'assets/images/new-svg/check.svg',
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
          const Spacer(),
          _bar(cp.border, 66),
          const SizedBox(height: 7),
          _bar(cp.border, 44),
          const SizedBox(height: 12),
          _bar(accent, double.infinity),
        ],
      ),
    );
  }

  Widget _bar(Color color, double width) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
