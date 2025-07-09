import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/widgets/stats_page/value_text.dart';
import 'package:provider/provider.dart';

class CompletedHabits extends StatelessWidget {
  const CompletedHabits({super.key});

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

    final statsProvider = context.watch<StatsProvider>();
    final colorProvider = context.watch<ColorProvider>();

    final habitsCompleted = statsProvider.habitsCompleted;
    final highestAmountOfHabitsLastWeek =
        statsProvider.highestAmountOfHabitsLastWeek;
    final habitsCompletedLastWeek = statsProvider.habitsCompletedLastWeek;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueText(text: "Completed habits: ", value: habitsCompleted),
        SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: colorProvider.colorScheme.standardColor,
            border: Border.all(color: colorProvider.colorScheme.strokeColor),
          ),
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          child: BarChart(
            BarChartData(
              // add horizontal lines for each interval 1
              barTouchData: BarTouchData(
                enabled: false,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem:
                      (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                        rod.toY.toString(),
                        TextStyle(color: colorProvider.textColor),
                      ),
                ),
              ),
              barGroups: List.generate(
                7,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: habitsCompletedLastWeek[index].toDouble(),
                      color: colorProvider.colorScheme.vividColor,
                      width: 5,
                    ),
                  ],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(),
                rightTitles: AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget:
                        (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(color: colorProvider.textColor),
                        ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget:
                        (value, meta) => Text(
                          getDay(value.toInt()),
                          style: TextStyle(color: colorProvider.textColor),
                        ),
                  ),
                ),
              ),
              maxY: highestAmountOfHabitsLastWeek.toDouble(),
            ),
          ),
        ),
      ],
    );
  }
}
