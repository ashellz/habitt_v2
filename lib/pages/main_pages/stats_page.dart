import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/stats_page/perfect_days_streak.dart';
import 'package:habitt/widgets/stats_page/completed_habits.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _tooltipController = SuperTooltipController();

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final statsProvider = context.watch<StatsProvider>();

    return DefaultAnnotatedRegion(
      child: GestureDetector(
        onTapDown: (context) => _tooltipController.hideTooltip(),
        child: Scaffold(
          backgroundColor: tp.backgroundColor,
          body: GradientBackground(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  statsProvider.refreshStats(force: true);
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      "Stats",
                      style: TextStyle(
                        fontSize: 38,
                        color: tp.primaryTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    PerfectDaysStreak(tooltipController: _tooltipController),
                    SizedBox(height: 12),
                    CompletedHabits(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
