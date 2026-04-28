import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
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
  });

  final ColorProvider cp;
  final List<double> completionRateLastWeek;

  @override
  Widget build(BuildContext context) {
    String getDay(int day) {
      final DateTime now = DateTime.now();
      final DateTime targetDay = now.subtract(Duration(days: 6 - day));

      // Get weekday name
      switch (targetDay.weekday) {
        case DateTime.monday:
          return "Mon";
        case DateTime.tuesday:
          return "Tue";
        case DateTime.wednesday:
          return "Wed";
        case DateTime.thursday:
          return "Thu";
        case DateTime.friday:
          return "Fri";
        case DateTime.saturday:
          return "Sat";
        case DateTime.sunday:
          return "Sun";
        default:
          return "";
      }
    }

    final sp = context.watch<StatsProvider>();

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
              CompletionRate(percentage: sp.completionRateLastWeek),
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
  });

  final int streak;
  final int longestStreak;
  final Map<DateTime, double> allStats;
  final Map<DateTime, bool> perfectDayCompletion;

  @override
  Widget build(BuildContext context) {
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
        StreakCalendar(
          allStats: allStats,
          perfectDayCompletion: perfectDayCompletion,
        ),
      ],
    );
  }
}
