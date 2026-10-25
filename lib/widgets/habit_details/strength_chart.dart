import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Habit strength (0-100%) over every day the habit was scheduled, plotted on
/// a real time axis from [from] to [to] so days without the habit show up as
/// gaps in the x spacing. Changing the window or data animates.
class StrengthChart extends StatelessWidget {
  const StrengthChart({
    super.key,
    required this.dates,
    required this.values,
    required this.from,
    required this.to,
  }) : assert(dates.length == values.length);

  final List<DateTime> dates;
  final List<double> values;
  final DateTime from;
  final DateTime to;

  static const double _height = 170;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final locale = Localizations.localeOf(context).toString();

    final first = from;
    final spanDays = _dayOffset(to, first).toDouble();
    final spansYears = spanDays > 365;
    final dateFormat =
        spansYears ? DateFormat.yMMM(locale) : DateFormat.MMMd(locale);
    final tooltipFormat = DateFormat.yMMMd(locale);

    final spots = [
      for (var i = 0; i < dates.length; i++)
        FlSpot(_dayOffset(dates[i], first).toDouble(), values[i] * 100),
    ];

    return SizedBox(
      height: _height,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: LineChart(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          LineChartData(
            minX: 0,
            maxX: spanDays,
            minY: 0,
            maxY: 100,
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: 50,
              getDrawingHorizontalLine:
                  (_) => FlLine(color: cp.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 50,
                  getTitlesWidget:
                      (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          '${value.round()}%',
                          style: TextStyle(
                            color: cp.lightGreyText,
                            fontSize: 11,
                          ),
                        ),
                      ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  // start, middle and end of the range
                  interval: spanDays / 2,
                  getTitlesWidget: (value, meta) {
                    final day = first.add(Duration(days: value.round()));
                    return SideTitleWidget(
                      meta: meta,
                      fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                      child: Text(
                        dateFormat.format(day),
                        style: TextStyle(color: cp.lightGreyText, fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => cp.habitBg,
                getTooltipItems:
                    (touched) => [
                      for (final spot in touched)
                        LineTooltipItem(
                          '${tooltipFormat.format(first.add(Duration(days: spot.x.round())))}\n'
                          '${spot.y.round()}%',
                          TextStyle(color: cp.text, fontSize: 13),
                        ),
                    ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.15,
                preventCurveOverShooting: true,
                color: cp.main,
                barWidth: 2.5,
                dotData: FlDotData(show: spots.length <= 2),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cp.main.withValues(alpha: 0.25),
                      cp.main.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // calendar days apart, immune to daylight-saving hour shifts
  static int _dayOffset(DateTime day, DateTime from) {
    return DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  }
}
