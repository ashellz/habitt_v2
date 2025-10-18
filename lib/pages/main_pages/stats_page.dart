import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/stats_page/all_habits_completed_streak.dart';
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
    final colorProvider = context.watch<ColorProvider>();
    final statsProvider = context.watch<StatsProvider>();

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: colorProvider.backgroundColor,
        statusBarIconBrightness:
            colorProvider.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colorProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light, // for iOS
      ),
      child: GestureDetector(
        onTapDown: (context) => _tooltipController.hideTooltip(),
        child: Scaffold(
          backgroundColor: colorProvider.backgroundColor,
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
                        color: colorProvider.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    AllHabitsCompletedStreak(
                      tooltipController: _tooltipController,
                    ),
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
