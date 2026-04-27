import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/widgets/stats/consistency_calendar.dart';
import 'package:habitt/widgets/stats/counter_stat_card.dart';
import 'package:habitt/widgets/stats/streak_calendar.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StatsProvider>();
    final hp = context.watch<HabitProvider>();

    final streak = sp.perfectDaysStreak;
    final longestStreak = sp.longestPerfectDaysStreak;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20),
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
            StreakCalendarSection(streak: streak, longestStreak: longestStreak),
            SizedBox(height: 32),
            ConsistencyCalendar(allStats: sp.getAllDaysProgress(hp)),
          ],
        ),
      ),
    );
  }
}

class StreakCalendarSection extends StatelessWidget {
  const StreakCalendarSection({
    super.key,
    required this.streak,
    required this.longestStreak,
  });

  final int streak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StatsProvider>();
    final hp = context.watch<HabitProvider>();

    return Column(
      spacing: 20,
      children: [
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
        StreakCalendar(allStats: sp.getAllDaysProgress(hp)),
      ],
    );
  }
}
