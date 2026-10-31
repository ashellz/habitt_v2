import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:habitt/widgets/habit_details/strength_chart.dart';
import 'package:habitt/widgets/stats/stats_range_selector.dart';
import 'package:provider/provider.dart';

class StrengthOverTimeSection extends StatefulWidget {
  const StrengthOverTimeSection({super.key, required this.stats});

  final HabitStatsData stats;

  @override
  State<StrengthOverTimeSection> createState() =>
      _StrengthOverTimeSectionState();
}

class _StrengthOverTimeSectionState extends State<StrengthOverTimeSection> {
  StatsRange _range = StatsRange.week;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final stats = widget.stats;
    final window = _window(stats);
    final hasChart = window.dates.isNotEmpty && window.spanDays >= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.strengthOverTime,
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            StatsRangeSelector(
              range: _range,
              onChanged: (range) => setState(() => _range = range),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ─── Chart ────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          decoration: ShapeDecoration(
            color: cp.habitBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child:
              hasChart
                  ? StrengthChart(
                    dates: window.dates,
                    values: window.values,
                    from: window.from,
                    to: window.to,
                  )
                  : Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 12,
                    ),
                    child: Text(
                      loc.strengthChartNotEnoughData,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                    ),
                  ),
        ),
      ],
    );
  }

  // the part of the strength history inside the selected range; 7D and 30D
  // always end today, ALL starts at the first scored day
  _Window _window(HabitStatsData stats) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all = stats.strengthDates;
    final from = _range.startFor(today) ?? (all.isEmpty ? today : all.first);

    final dates = <DateTime>[];
    final values = <double>[];
    for (var i = 0; i < all.length; i++) {
      if (all[i].isBefore(from)) continue;
      dates.add(all[i]);
      values.add(stats.strengthHistory[i]);
    }

    return _Window(from: from, to: today, dates: dates, values: values);
  }
}

class _Window {
  const _Window({
    required this.from,
    required this.to,
    required this.dates,
    required this.values,
  });

  final DateTime from;
  final DateTime to;
  final List<DateTime> dates;
  final List<double> values;

  int get spanDays => to.difference(from).inDays;
}
