import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';
import 'package:tinycolor2/tinycolor2.dart';

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
          body: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                statsProvider.refreshStats(force: true);
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
    );
  }
}

class AllHabitsCompletedStreak extends StatelessWidget {
  const AllHabitsCompletedStreak({super.key, required this.tooltipController});

  final SuperTooltipController tooltipController;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final statsProvider = context.watch<StatsProvider>();

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: double.infinity,

          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorProvider.colorScheme.standardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorProvider.colorScheme.strokeColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "All habits completed streak",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: colorProvider.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    "assets/images/icons/streak.png",
                    scale: 0.75,
                    color:
                        statsProvider.allHabitsCompletedStreak == 0
                            ? colorProvider.disabledColor.lighten()
                            : null,
                  ),
                  Transform.translate(
                    offset: Offset(0, 5),
                    child: Text(
                      statsProvider.allHabitsCompletedStreak.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        color:
                            statsProvider.allHabitsCompletedStreak == 0
                                ? colorProvider.colorScheme.vividColor
                                : Color(0xFF212529),
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
              await tooltipController.showTooltip();
            },
            child: SuperTooltip(
              controller: tooltipController,
              backgroundColor: colorProvider.standardColor,
              content: Text(
                "Number of days in a row you have completed all your habits.",
                style: TextStyle(color: colorProvider.textColor),
              ),
              showBarrier: false,

              child: Icon(
                Icons.info_outline,
                size: 24,
                color: colorProvider.mutedTextColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
            borderRadius: BorderRadius.circular(12),
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

class ValueText extends StatelessWidget {
  const ValueText({super.key, required this.text, required this.value});

  final String text;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 22,
              color: colorProvider.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: value.toString(),
            style: TextStyle(
              fontSize: 22,
              color: colorProvider.colorScheme.vividColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
