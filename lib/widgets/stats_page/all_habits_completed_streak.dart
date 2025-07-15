import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/widgets/glass_feel_container.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:tinycolor2/tinycolor2.dart';

class AllHabitsCompletedStreak extends StatelessWidget {
  const AllHabitsCompletedStreak({super.key, required this.tooltipController});

  final SuperTooltipController tooltipController;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final statsProvider = context.watch<StatsProvider>();

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GlassFeelContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "All habits completed streak",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: colorProvider.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    "assets/images/icons/streak.png",
                    scale: 0.75,
                    color:
                        statsProvider.allHabitsCompletedStreak == 0
                            ? colorProvider.disabledColor.lighten()
                            : null,
                  ),
                  Transform.translate(
                    offset: Offset(0, 5),
                    child: Text(
                      statsProvider.allHabitsCompletedStreak.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        color:
                            statsProvider.allHabitsCompletedStreak == 0
                                ? colorProvider.colorScheme.vividColor
                                : Color(0xFF212529),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 12),
          child: GestureDetector(
            onTap: () async {
              await tooltipController.showTooltip();
            },
            child: SuperTooltip(
              controller: tooltipController,
              backgroundColor: colorProvider.standardColor,
              content: Text(
                "Number of days in a row you have completed all your habits.",
                style: TextStyle(color: colorProvider.textColor),
              ),
              showBarrier: false,

              child: Icon(
                Icons.info_outline,
                size: 24,
                color: colorProvider.mutedTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
