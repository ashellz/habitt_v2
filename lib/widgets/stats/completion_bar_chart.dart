import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// One bar per day (completion 0-100), oldest first, the last bar is today.
/// Seven bars are labelled by weekday, longer ranges by date once a week
/// counting back from today.
class CompletionBarChart extends StatelessWidget {
  const CompletionBarChart({super.key, required this.rates, this.today});

  final List<double> rates;
  final DateTime? today;

  static const double _leftTitlesSize = 43;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final now = today ?? DateTime.now();
    final count = rates.length;
    final byWeekday = count <= 7;
    final dateFormat = DateFormat.MMMd(locale);

    DateTime dayAt(int index) =>
        DateTime(now.year, now.month, now.day - (count - 1 - index));

    String weekdayLabel(DateTime day) {
      final raw = switch (day.weekday) {
        DateTime.monday => loc.mon,
        DateTime.tuesday => loc.tue,
        DateTime.wednesday => loc.wed,
        DateTime.thursday => loc.thu,
        DateTime.friday => loc.fri,
        DateTime.saturday => loc.sat,
        _ => loc.sun,
      };
      return raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
    }

    return SizedBox(
      height: 132,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 30 wide for a week, thinner as more days have to fit
          final barWidth =
              byWeekday
                  ? 30.0
                  : ((constraints.maxWidth - _leftTitlesSize) / count * 0.6)
                      .clamp(2.0, 30.0);

          return BarChart(
            BarChartData(
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
                count,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: rates[index],
                      // today in the full accent, the other days as a soft
                      // step of it (opaque, so the grid lines don't show
                      // through the bars)
                      color:
                          index == count - 1
                              ? cp.main
                              : Color.alphaBlend(
                                cp.main.withValues(
                                  alpha: cp.isDark ? 0.4 : 0.24,
                                ),
                                cp.habitBg,
                              ),
                      width: barWidth,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(barWidth < 16 ? 3 : 8),
                        topRight: Radius.circular(barWidth < 16 ? 3 : 8),
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
                    reservedSize: _leftTitlesSize,
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
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      // longer ranges: today and every 7th day before it
                      if (!byWeekday && (count - 1 - index) % 7 != 0) {
                        return const SizedBox.shrink();
                      }
                      final day = dayAt(index);
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                        child: Text(
                          byWeekday ? weekdayLabel(day) : dateFormat.format(day),
                          softWrap: false,
                          style: TextStyle(
                            color: cp.lightGreyText,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              maxY: 100,
            ),
          );
        },
      ),
    );
  }
}
