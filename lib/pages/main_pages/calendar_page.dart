import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/widgets/stats/completion_rate.dart';
import 'package:habitt/widgets/stats/completion_ratio_text.dart';
import 'package:habitt/widgets/stats/consistency_calendar.dart';
import 'package:habitt/widgets/stats/counter_stat_card.dart';
import 'package:habitt/widgets/stats/streak_calendar.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  static Widget demo() => const _DemoCalendarBody();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StatsProvider>();
    final hp = context.watch<HabitProvider>();
    final allStats = sp.getAllDaysProgress(hp);
    final perfectDayCompletion = sp.getPerfectDayCompletion(hp);
    final completionRateLastWeek = sp.getCompletionRateLastWeekByDay(hp);

    final streak = sp.perfectDaysStreak;
    final longestStreak = sp.longestPerfectDaysStreak;

    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: ListView(
          children: [
            Text(
              loc.calendar,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24),
            StreakCalendarSection(
              streak: streak,
              longestStreak: longestStreak,
              allStats: allStats,
              perfectDayCompletion: perfectDayCompletion,
            ),
            SizedBox(height: 32),
            CompletionRatio(
              cp: cp,
              completionRateLastWeek: completionRateLastWeek,
            ),
            SizedBox(height: 32),
            ConsistencyCalendar(allStats: allStats),
            SizedBox(height: 145),
          ],
        ),
      ),
    );
  }
}

class CompletionRatio extends StatelessWidget {
  const CompletionRatio({
    super.key,
    required this.cp,
    required this.completionRateLastWeek,
    this.today,
    this.overridePercentage,
  });

  final ColorProvider cp;
  final List<double> completionRateLastWeek;
  final DateTime? today;
  final int? overridePercentage;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    String getDay(int day) {
      final DateTime now = today ?? DateTime.now();
      final DateTime targetDay = now.subtract(Duration(days: 6 - day));

      String raw;
      switch (targetDay.weekday) {
        case DateTime.monday:
          raw = loc.mon;
        case DateTime.tuesday:
          raw = loc.tue;
        case DateTime.wednesday:
          raw = loc.wed;
        case DateTime.thursday:
          raw = loc.thu;
        case DateTime.friday:
          raw = loc.fri;
        case DateTime.saturday:
          raw = loc.sat;
        case DateTime.sunday:
          raw = loc.sun;
        default:
          return "";
      }
      return raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
    }

    final percentage =
        overridePercentage ?? context.watch<StatsProvider>().completionRateLastWeek;

    return Column(
      spacing: 20,
      children: [
        CompletionRatioText(),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: cp.habitBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Column(
            spacing: 20,
            children: [
              CompletionRate(percentage: percentage),
              SizedBox(
                height: 132,
                child: BarChart(
                  BarChartData(
                    // add horizontal lines for each interval 1
                    barTouchData: BarTouchData(enabled: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      drawHorizontalLine: true,
                      horizontalInterval: 50,
                      getDrawingHorizontalLine:
                          (value) => FlLine(color: cp.border, strokeWidth: 1),
                    ),
                    barGroups: List.generate(
                      7,
                      (index) => BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: completionRateLastWeek[index],
                            color:
                                index == 6
                                    ? cp.main
                                    : cp.isDark
                                    ? Color(0xFF3C6D59)
                                    : Color(0xFFBBF3DC),
                            width: 30,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.symmetric(
                        horizontal: BorderSide(color: cp.border, width: 1),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(),
                      rightTitles: AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 43,
                          getTitlesWidget:
                              (value, meta) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  value == 0
                                      ? '0%'
                                      : value == 50
                                      ? '50%'
                                      : value == 100
                                      ? '100%'
                                      : '',

                                  style: TextStyle(
                                    color: cp.lightGreyText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,

                          getTitlesWidget:
                              (value, meta) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  getDay(value.toInt()),
                                  style: TextStyle(
                                    color: cp.lightGreyText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                    maxY: 100,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StreakCalendarSection extends StatelessWidget {
  const StreakCalendarSection({
    super.key,
    required this.streak,
    required this.longestStreak,
    required this.allStats,
    required this.perfectDayCompletion,
    this.today,
  });

  final int streak;
  final int longestStreak;
  final Map<DateTime, double> allStats;
  final Map<DateTime, bool> perfectDayCompletion;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      spacing: 20,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CounterStatCard(
                  title: loc.currentStreak,
                  iconPath: 'assets/images/new-svg/streak.svg',
                  value: streak,
                  formatter:
                      (value) =>
                          value == 1 ? '1 ${loc.day}' : '$value ${loc.days}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CounterStatCard(
                  title: loc.longestStreak,
                  iconPath: 'assets/images/new-svg/longest-streak.svg',
                  value: longestStreak,
                  formatter:
                      (value) =>
                          value == 1 ? '1 ${loc.day}' : '$value ${loc.days}',
                ),
              ),
            ],
          ),
        ),
        StreakCalendar(
          allStats: allStats,
          perfectDayCompletion: perfectDayCompletion,
          today: today,
        ),
      ],
    );
  }
}

class _DemoCalendarBody extends StatelessWidget {
  const _DemoCalendarBody();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    final realNow = DateTime.now();
    final demoToday = DateTime(realNow.year, realNow.month, 9);
    final seeded = Random(realNow.year * 100 + realNow.month);

    const completedDays = {2, 5, 7, 8, 9};

    final allStats = <DateTime, double>{};
    for (int d = 1; d <= 9; d++) {
      final date = DateTime(realNow.year, realNow.month, d);
      if (completedDays.contains(d)) {
        allStats[date] = 1.0;
      } else {
        allStats[date] = 0.15 + seeded.nextDouble() * 0.7;
      }
    }

    final perfectDayCompletion = <DateTime, bool>{
      for (final d in completedDays)
        DateTime(realNow.year, realNow.month, d): true,
    };

    final completionRateLastWeek = List<double>.generate(7, (index) {
      final dayOfMonth = 3 + index;
      if (completedDays.contains(dayOfMonth)) {
        return 100.0;
      }
      return 20.0 + seeded.nextDouble() * 50.0;
    });

    const streak = 3;
    const longestStreak = 10;
    const completionPercentage = 71;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: ListView(
          children: [
            Text(
              loc.calendar,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            StreakCalendarSection(
              streak: streak,
              longestStreak: longestStreak,
              allStats: allStats,
              perfectDayCompletion: perfectDayCompletion,
              today: demoToday,
            ),
            const SizedBox(height: 32),
            CompletionRatio(
              cp: cp,
              completionRateLastWeek: completionRateLastWeek,
              today: demoToday,
              overridePercentage: completionPercentage,
            ),
            const SizedBox(height: 32),
            ConsistencyCalendar(allStats: allStats, today: demoToday),
            const SizedBox(height: 145),
          ],
        ),
      ),
    );
  }
}
