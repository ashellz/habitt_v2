import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/widgets/default/glass_feel_container.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:habitt/l10n/app_localizations.dart';

class PerfectDaysStreak extends StatelessWidget {
  const PerfectDaysStreak({super.key, required this.tooltipController});

  final SuperTooltipController tooltipController;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final statsProvider = context.watch<StatsProvider>();

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GlassFeelContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context)!.perfectDaysStreak,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: tp.primaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset("assets/images/icons/streak.png", scale: 0.75),
                  Transform.translate(
                    offset: Offset(0, 5),
                    child: Text(
                      statsProvider.perfectDaysStreak.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        color: Color(0xFF212529),
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
              if (tooltipController.isVisible) {
                await tooltipController.hideTooltip();
                return;
              }
              await tooltipController.showTooltip();
            },
            child: SuperTooltip(
              hasShadow: false,
              controller: tooltipController,
              backgroundColor: tp.surfaceColor,
              content: Text(
                AppLocalizations.of(context)!.numberOfDaysInARowYouHaveCompletedAllYourHabits,
                style: TextStyle(color: tp.primaryTextColor),
              ),
              showBarrier: false,

              child: Icon(
                Icons.info_outline,
                size: 24,
                color: tp.secondaryTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
