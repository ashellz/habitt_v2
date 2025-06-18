import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:provider/provider.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String getDay(int day) {
    switch (day) {
      case 0:
        return "Mon";
      case 1:
        return "Tue";
      case 2:
        return "Wed";
      case 3:
        return "Thu";
      case 4:
        return "Fri";
      case 5:
        return "Sat";
      case 6:
        return "Sun";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final statsProvider = context.watch<StatsProvider>();

    final habitsCompleted = statsProvider.habitsCompleted;
    final highestAmountOfHabitsLastWeek =
        statsProvider.highestAmountOfHabitsLastWeek;

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
      child: Scaffold(
        backgroundColor: colorProvider.backgroundColor,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              statsProvider.refreshStats();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              children: [
                Text(
                  "Stats",
                  style: TextStyle(
                    fontSize: 38,
                    color: colorProvider.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Completed habits: ",
                        style: TextStyle(
                          fontSize: 22,
                          color: colorProvider.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: habitsCompleted.toString(),
                        style: TextStyle(
                          fontSize: 22,
                          color: colorProvider.colorScheme.vividColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorProvider.colorScheme.standardColor,
                    border: Border.all(
                      color: colorProvider.colorScheme.strokeColor,
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: BarChart(
                    BarChartData(
                      barGroups: List.generate(
                        7,
                        (index) => BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: highestAmountOfHabitsLastWeek.toDouble(),
                              color: colorProvider.colorScheme.vividColor,
                              width: 5,
                            ),
                          ],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget:
                                (value, meta) => Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: colorProvider.textColor,
                                  ),
                                ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget:
                                (value, meta) => Text(
                                  getDay(value.toInt()),
                                  style: TextStyle(
                                    color: colorProvider.textColor,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
