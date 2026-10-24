import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:habitt/widgets/stats/completion_rate.dart';
import 'package:habitt/widgets/stats/stats_range_selector.dart';
import 'package:habitt/widgets/stats/value_blur_cloud.dart';
import 'package:provider/provider.dart';

/// Completion ratio with best / worst weekday, switchable between 7D, 30D, ALL.
class CompletionRatioSection extends StatefulWidget {
  const CompletionRatioSection({super.key, required this.stats});

  final HabitStatsData stats;

  @override
  State<CompletionRatioSection> createState() => _CompletionRatioSectionState();
}

class _CompletionRatioSectionState extends State<CompletionRatioSection> {
  StatsRange _range = StatsRange.week;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final rangeStats = widget.stats.rangeStats[_range]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Header ───────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              loc.completionRatio,
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
        // ─── Card ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: cp.habitBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Row(
            spacing: 12,
            children: [
              CompletionRate(
                percentage: (rangeStats.completionRatio * 100).round(),
              ),
              Container(width: 1, height: 33, color: cp.border),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    WeekdayRateRow(
                      label: rangeStats.bestWeekday.label,
                      percentage: rangeStats.bestWeekday.percentage,
                    ),
                    const SizedBox(height: 10),
                    WeekdayRateRow(
                      label: rangeStats.worstWeekday.label,
                      percentage: rangeStats.worstWeekday.percentage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WeekdayRateRow extends StatefulWidget {
  const WeekdayRateRow({
    super.key,
    required this.label,
    required this.percentage,
  });

  final String label;
  final int percentage;

  @override
  State<WeekdayRateRow> createState() => _WeekdayRateRowState();
}

class _WeekdayRateRowState extends State<WeekdayRateRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late int _currentPercentage;

  @override
  void initState() {
    super.initState();
    _currentPercentage = widget.percentage.clamp(0, 100);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = AlwaysStoppedAnimation(_currentPercentage.toDouble());
  }

  @override
  void didUpdateWidget(covariant WeekdayRateRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextPercentage = widget.percentage.clamp(0, 100);
    if (nextPercentage == _currentPercentage) {
      return;
    }

    _animation = Tween<double>(
      begin: _currentPercentage.toDouble(),
      end: nextPercentage.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _currentPercentage = nextPercentage;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedPercentage = _animation.value.round();

        return Row(
          spacing: 4,
          children: [
            Text(
              "${widget.label[0].toUpperCase()}${widget.label.substring(1).toLowerCase()}",
              style: TextStyle(color: cp.lightGreyText, fontSize: 13),
            ),
            Text('-', style: TextStyle(color: cp.lightGreyText, fontSize: 13)),
            ValueBlurCloud(
              progress: _controller.value,
              borderRadius: BorderRadius.circular(6),
              child: Text(
                '$animatedPercentage%',
                style: TextStyle(
                  color: cp.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
