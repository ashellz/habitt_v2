import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/models/streak_health.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.streak,
    this.health = StreakHealth.healthy,
  });

  final int streak;

  final StreakHealth health;

  String get _iconAsset => switch (health) {
    StreakHealth.healthy ||
    StreakHealth.dormant => "assets/images/new-svg/streak.svg",
    StreakHealth.fading => "assets/images/new-svg/streak-fade.svg",
    StreakHealth.critical => "assets/images/new-svg/ice-left.svg",
  };

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    if (streak == 0) return const SizedBox.shrink();

    Color getBgColor() {
      return switch (health) {
        StreakHealth.healthy || StreakHealth.dormant => cp.orange100,
        StreakHealth.fading => cp.orange100,
        StreakHealth.critical => cp.rightBlueGradient,
      };
    }

    Color getBorderColor() {
      return switch (health) {
        StreakHealth.healthy || StreakHealth.dormant => cp.orange200,
        StreakHealth.fading => cp.orange200,
        StreakHealth.critical => cp.blueCircle,
      };
    }

    Color getTextColor() {
      return switch (health) {
        StreakHealth.healthy || StreakHealth.dormant => cp.orange300,
        StreakHealth.fading => cp.orange300,
        StreakHealth.critical => cp.blueCircle.lighten(),
      };
    }

    return Container(
      height: 27,
      decoration: BoxDecoration(
        color: getBgColor(),
        border: Border.all(color: getBorderColor(), width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        spacing: 5,
        children: [
          if (health == StreakHealth.critical)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (health == StreakHealth.critical)
                    SvgPicture.asset(
                      "assets/images/new-svg/streak.svg",
                      width: 16,
                      height: 16,
                    ),
                  SvgPicture.asset(_iconAsset, width: 24, height: 24),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
              child: Transform.scale(
                scale: health == StreakHealth.fading ? 1.4 : 1,
                child: Transform.translate(
                  offset:
                      health == StreakHealth.fading
                          ? Offset(1.4, 1)
                          : Offset.zero,
                  child: SvgPicture.asset(_iconAsset, width: 16, height: 16),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 3, bottom: 3),
            child: Text(
              streak.toString(),
              style: TextStyle(
                color: getTextColor(),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
