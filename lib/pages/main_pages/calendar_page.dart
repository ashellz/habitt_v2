import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/widgets/stats/counter_stat_card.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StatsProvider>();

    final streak = sp.perfectDaysStreak;
    final longestStreak = sp.longestPerfectDaysStreak;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: ListView(
          children: [
            Text(
              'Calendar',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CounterStatCard(
                    title: 'Current streak',
                    iconPath: 'assets/images/new-svg/streak.svg',
                    value: streak,
                    formatter: (value) => value == 1 ? '1 day' : '$value days',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CounterStatCard(
                    title: 'Longest streak',
                    iconPath: 'assets/images/new-svg/longest-streak.svg',
                    value: longestStreak,
                    formatter: (value) => value == 1 ? '1 day' : '$value days',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
