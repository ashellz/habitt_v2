import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/whats_new/whats_new_graphic_frame.dart';
import 'package:provider/provider.dart';

/// Apple Health on iOS, Health Connect elsewhere, with the metrics a habit can
/// be linked to as tilted tiles.
class WhatsNewHealthGraphic extends StatelessWidget {
  const WhatsNewHealthGraphic({super.key});

  static const _metrics = [
    'steps',
    'sleep',
    'workout',
    'mindfullnes',
    'burned_calories',
    'total_calories',
  ];
  static const _tilts = [-0.10, 0.07, -0.05, 0.09, -0.08, 0.06];
  static const _drops = [0.0, 8.0, 2.0, 8.0, 0.0, 6.0];

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isIOS = Platform.isIOS;

    return WhatsNewGraphicFrame(
      glows: [
        WhatsNewGlow(
          color: cp.main,
          alignment: const Alignment(-1.2, 1.3),
          size: 260,
        ),
        const WhatsNewGlow(
          color: Color(0xFF3CACFF),
          alignment: Alignment(1.3, -1.3),
          size: 240,
        ),
        const WhatsNewGlow(
          color: Color(0xFFFF6B9A),
          alignment: Alignment(1.2, 1.2),
          size: 160,
          strength: 0.25,
        ),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 22,
        children: [
          // ─── Source ───────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3CACFF).withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child:
                    isIOS
                        ? SvgPicture.asset(
                          'assets/images/widget-images/apple-health.svg',
                        )
                        : Image.asset(
                          'assets/images/widget-images/health-connect.png',
                        ),
              ),
              Flexible(
                child: Text(
                  isIOS ? 'Apple Health' : 'Health Connect',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          // ─── Metrics ──────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              for (var i = 0; i < _metrics.length; i++)
                Transform.translate(
                  offset: Offset(0, _drops[i]),
                  child: Transform.rotate(
                    angle: _tilts[i],
                    child: _MetricTile(name: _metrics[i]),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: cp.graphicCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cp.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: cp.isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Image.asset('assets/images/health-icons/$name.png'),
    );
  }
}
