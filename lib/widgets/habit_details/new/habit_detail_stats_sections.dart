import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
import 'package:habitt/widgets/stats/completion_rate.dart';
import 'package:habitt/widgets/stats/completion_ratio_text.dart';
import 'package:habitt/widgets/stats/counter_stat_card.dart';
import 'package:habitt/widgets/stats/stat_card.dart';
import 'package:habitt/widgets/stats/value_blur_cloud.dart';
import 'package:provider/provider.dart';

class HabitDetailStatsSections extends StatelessWidget {
  const HabitDetailStatsSections({
    super.key,
    required this.habit,
    required this.stats,
  });

  final Habit habit;
  final HabitStatsData stats;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatsGrid(habit: habit, stats: stats),
        const SizedBox(height: 28),
        CompletionRatioText(),
        const SizedBox(height: 14),
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
                percentage: (stats.completionRatioLast7Days * 100).round(),
              ),
              Container(width: 1, height: 33, color: cp.border),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _WeekdayRateRow(
                      label: stats.bestWeekday.label,
                      percentage: stats.bestWeekday.percentage,
                    ),
                    const SizedBox(height: 10),
                    _WeekdayRateRow(
                      label: stats.worstWeekday.label,
                      percentage: stats.worstWeekday.percentage,
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.habit, required this.stats});

  final Habit habit;
  final HabitStatsData stats;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CounterStatCard(
                title: loc.completed,
                iconPath: 'assets/images/new-svg/completed.svg',
                value: stats.completedCount,
                formatter: (value) => '$value',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CounterStatCard(
                title: loc.skipped,
                iconPath: 'assets/images/new-svg/skipped.svg',
                value: stats.missedCount,
                formatter: (value) => '$value',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CounterStatCard(
                title: loc.currentStreak,
                iconPath: 'assets/images/new-svg/streak.svg',
                value: stats.currentStreak,
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
                value: stats.longestStreak,
                formatter:
                    (value) =>
                        value == 1 ? '1 ${loc.day}' : '$value ${loc.days}',
              ),
            ),
          ],
        ),
        if (habit.tracksAmount || habit.tracksDuration) ...[
          const SizedBox(height: 10),
          _TotalSpentCard(habit: habit, stats: stats),
        ],
      ],
    );
  }
}

class _TotalSpentCard extends StatefulWidget {
  const _TotalSpentCard({required this.habit, required this.stats});

  final Habit habit;
  final HabitStatsData stats;

  @override
  State<_TotalSpentCard> createState() => _TotalSpentCardState();
}

class _TotalSpentCardState extends State<_TotalSpentCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late int _currentRawValue;

  int _rawValueFor(Habit habit, HabitStatsData stats) {
    if (habit.tracksDuration) {
      return stats.totalDurationCompletedMinutes;
    }
    return stats.totalAmountCompleted;
  }

  @override
  void initState() {
    super.initState();
    _currentRawValue = _rawValueFor(
      widget.habit,
      widget.stats,
    ).clamp(0, 999999999);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = AlwaysStoppedAnimation(_currentRawValue.toDouble());
  }

  @override
  void didUpdateWidget(covariant _TotalSpentCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextRawValue = _rawValueFor(
      widget.habit,
      widget.stats,
    ).clamp(0, 999999999);
    if (nextRawValue == _currentRawValue) {
      return;
    }

    _animation = Tween<double>(
      begin: _currentRawValue.toDouble(),
      end: nextRawValue.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _currentRawValue = nextRawValue;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final loc = AppLocalizations.of(context)!;
    final title = habit.tracksDuration ? loc.duration : loc.amount;
    final iconPath =
        habit.tracksDuration
            ? 'assets/images/new-svg/clock.svg'
            : 'assets/images/new-svg/amount.svg';

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedRaw = _animation.value.round();
        final value =
            habit.tracksDuration
                ? getDurationString(animatedRaw)
                : '$animatedRaw ${resolveAmountLabelForValue(habit.amountLabel.isEmpty ? loc.times : habit.amountLabel, animatedRaw, loc)}';

        return StatCard(
          title: title,
          value: value,
          iconPath: iconPath,
          fullWidth: true,
          cloudProgress: _controller.value,
        );
      },
    );
  }
}

class _WeekdayRateRow extends StatefulWidget {
  const _WeekdayRateRow({required this.label, required this.percentage});

  final String label;
  final int percentage;

  @override
  State<_WeekdayRateRow> createState() => _WeekdayRateRowState();
}

class _WeekdayRateRowState extends State<_WeekdayRateRow>
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
  void didUpdateWidget(covariant _WeekdayRateRow oldWidget) {
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
