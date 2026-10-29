import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_details/strength_chart.dart';
import 'package:habitt/widgets/whats_new/whats_new_graphic_frame.dart';
import 'package:provider/provider.dart';

/// The real strength chart from the habit details, drawn with sample data of a
/// habit that keeps getting stronger.
class WhatsNewStrengthGraphic extends StatelessWidget {
  const WhatsNewStrengthGraphic({super.key});

  static const int _days = 30;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = [
      for (var i = 0; i < _days; i++)
        today.subtract(Duration(days: _days - 1 - i)),
    ];
    final values = [
      for (var i = 0; i < _days; i++)
        (0.22 + 0.66 * (1 - math.exp(-i / 11)) + 0.04 * math.sin(i * 1.3))
            .clamp(0.0, 1.0),
    ];

    return WhatsNewGraphicFrame(
      glows: [
        WhatsNewGlow(
          color: cp.main,
          alignment: const Alignment(1.2, -1.3),
          size: 280,
          strength: 0.4,
        ),
        const WhatsNewGlow(
          color: Color(0xFF3CACFF),
          alignment: Alignment(-1.3, 1.3),
          size: 220,
          strength: 0.3,
        ),
      ],
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.strengthOverTime,
                        style: TextStyle(
                          color: cp.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cp.mainTint,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: cp.mainBorder, width: 1),
                      ),
                      child: Text(
                        '${(values.last * 100).round()}%',
                        style: TextStyle(
                          color: cp.main,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              StrengthChart(
                dates: dates,
                values: values,
                from: dates.first,
                to: dates.last,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
