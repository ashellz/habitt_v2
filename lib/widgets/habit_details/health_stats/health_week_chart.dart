import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/health_history.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// The last days of a Health habit against its target: bars for counts and
/// durations, dots on a time axis (with the on-time band) for bedtime and
/// wake time.
class HealthWeekChart extends StatelessWidget {
  const HealthWeekChart({super.key, required this.history});

  final HealthHistory history;

  static const double _height = 150;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _height,
          child:
              history.kind == HealthHistoryKind.timeOfDay
                  ? _timeOfDayChart(context, cp)
                  : _barChart(context, cp),
        ),
        if (history.target > 0) ...[
          const SizedBox(height: 8),
          _legend(cp, loc),
        ],
      ],
    );
  }

  // ─── Legend ───────────────────────────────────────────

  Widget _legend(ColorProvider cp, AppLocalizations loc) {
    return Row(
      spacing: 6,
      children: [
        SizedBox(
          width: 18,
          child: CustomPaint(painter: _DashedLinePainter(color: cp.greyText)),
        ),
        Text(
          loc.target,
          style: TextStyle(color: cp.lightGreyText, fontSize: 12),
        ),
      ],
    );
  }

  // ─── Bar chart ────────────────────────────────────────

  Widget _barChart(BuildContext context, ColorProvider cp) {
    final points = history.points;
    final highest = points.fold<double>(
      history.target,
      (max, p) => (p.value ?? 0) > max ? p.value! : max,
    );
    final maxY = highest <= 0 ? 1.0 : highest * 1.15;

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, cp, showLeft: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (history.target > 0) _targetLine(cp, history.target),
          ],
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => cp.habitBg,
            getTooltipItem: (group, _, rod, _) {
              final point = points[group.x];
              if (point.value == null) return null;
              return BarTooltipItem(
                _formatValue(context, point.value!),
                TextStyle(color: cp.text, fontSize: 13),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].value ?? 0,
                  width: 14,
                  borderRadius: BorderRadius.circular(6),
                  color:
                      points[i].completed
                          ? cp.main
                          : cp.main.withValues(alpha: 0.35),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── Time-of-day chart ────────────────────────────────

  Widget _timeOfDayChart(BuildContext context, ColorProvider cp) {
    final points = history.points;
    final values = [
      for (final p in points)
        if (p.value != null) p.value!,
      if (history.target > 0) history.target,
      if (history.target > 0) history.target + history.tolerance,
    ];
    final lowest = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final highest =
        values.isEmpty ? 60.0 : values.reduce((a, b) => a > b ? a : b);
    // whole hours, so every axis label lands on a tick
    final minY = ((lowest - 30) / 60).floorToDouble() * 60;
    final maxY = ((highest + 30) / 60).ceilToDouble() * 60;

    final spots = [
      for (var i = 0; i < points.length; i++)
        points[i].value == null
            ? FlSpot.nullSpot
            : FlSpot(i.toDouble(), points[i].value!),
    ];

    return LineChart(
      LineChartData(
        minX: -0.5,
        maxX: points.length - 0.5,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 60,
          getDrawingHorizontalLine:
              (_) => FlLine(color: cp.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: _titles(context, cp, showLeft: true),
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            if (history.target > 0 && history.tolerance > 0)
              HorizontalRangeAnnotation(
                y1: history.target,
                y2: history.target + history.tolerance,
                color: cp.main.withValues(alpha: 0.15),
              ),
          ],
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (history.target > 0) _targetLine(cp, history.target),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => cp.habitBg,
            getTooltipItems:
                (touched) => [
                  for (final spot in touched)
                    LineTooltipItem(
                      _formatValue(context, spot.y),
                      TextStyle(color: cp.text, fontSize: 13),
                    ),
                ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: cp.border,
            barWidth: 1.5,
            dotData: FlDotData(
              getDotPainter: (spot, _, _, _) {
                final completed = points[spot.x.round()].completed;
                return FlDotCirclePainter(
                  radius: 5.5,
                  color:
                      completed ? cp.main : cp.main.withValues(alpha: 0.35),
                  strokeWidth: 0,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared ───────────────────────────────────────────

  HorizontalLine _targetLine(ColorProvider cp, double y) {
    return HorizontalLine(
      y: y,
      color: cp.greyText,
      strokeWidth: 1.5,
      dashArray: [5, 4],
    );
  }

  FlTitlesData _titles(
    BuildContext context,
    ColorProvider cp, {
    required bool showLeft,
  }) {
    final locale = Localizations.localeOf(context).toString();
    final today = DateTime.now();
    final lastDay = history.points.last.day;
    final isCurrentWeek =
        lastDay.year == today.year &&
        lastDay.month == today.month &&
        lastDay.day == today.day;

    return FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: showLeft,
          reservedSize: 52,
          interval: 60,
          getTitlesWidget: (value, meta) {
            if (value % 60 != 0) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              child: Text(
                _timeLabel(context, value),
                style: TextStyle(color: cp.lightGreyText, fontSize: 11),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          getTitlesWidget: (value, meta) {
            final index = value.round();
            if (value != index.toDouble() ||
                index < 0 ||
                index >= history.points.length) {
              return const SizedBox.shrink();
            }
            final isLast = index == history.points.length - 1;
            return SideTitleWidget(
              meta: meta,
              child: Text(
                DateFormat.EEEEE(locale).format(history.points[index].day),
                style: TextStyle(
                  color: isLast && isCurrentWeek ? cp.text : cp.lightGreyText,
                  fontSize: 12,
                  fontWeight:
                      isLast && isCurrentWeek
                          ? FontWeight.w600
                          : FontWeight.w400,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatValue(BuildContext context, double value) {
    switch (history.kind) {
      case HealthHistoryKind.timeOfDay:
        return _timeLabel(context, value);
      case HealthHistoryKind.duration:
        return getDurationString(value.round());
      case HealthHistoryKind.sleepMinutes:
        return getDurationString(value.round() * 60);
      case HealthHistoryKind.amount:
        return NumberFormat.decimalPattern(
          Localizations.localeOf(context).toString(),
        ).format(value.round());
    }
  }

  // minutes since midnight; bedtimes past midnight are stored as 24h+
  String _timeLabel(BuildContext context, double minutes) {
    final normalized = minutes.round() % (24 * 60);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.5;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + 5).clamp(0, size.width), size.height / 2),
        paint,
      );
      x += 9;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
