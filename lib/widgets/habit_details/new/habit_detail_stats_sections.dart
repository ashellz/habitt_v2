import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion ratio',
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text('Last 7 days', style: TextStyle(color: cp.lightGreyText)),
          ],
        ),
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
              _CompletionRatioLeft(
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Completed',
                value: '${stats.completedCount}',
                iconPath: 'assets/images/new-svg/completed.svg',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'Skipped',
                value: '${stats.missedCount}',
                iconPath: 'assets/images/new-svg/skipped.svg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Current streak',
                value:
                    stats.currentStreak == 1
                        ? '1 day'
                        : '${stats.currentStreak} days',
                iconPath: 'assets/images/new-svg/streak.svg',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'Longest streak',
                value:
                    stats.longestStreak == 1
                        ? '1 day'
                        : '${stats.longestStreak} days',
                iconPath: 'assets/images/new-svg/longest-streak.svg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _AnimatedTotalSpentCard(
          habit: habit,
          stats: stats,
        ),
      ],
    );
  }
}

class _AnimatedTotalSpentCard extends StatefulWidget {
  const _AnimatedTotalSpentCard({required this.habit, required this.stats});

  final Habit habit;
  final HabitStatsData stats;

  @override
  State<_AnimatedTotalSpentCard> createState() => _AnimatedTotalSpentCardState();
}

class _AnimatedTotalSpentCardState extends State<_AnimatedTotalSpentCard>
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
    _currentRawValue = _rawValueFor(widget.habit, widget.stats).clamp(0, 999999999);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _animation = AlwaysStoppedAnimation(_currentRawValue.toDouble());
  }

  @override
  void didUpdateWidget(covariant _AnimatedTotalSpentCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextRawValue = _rawValueFor(widget.habit, widget.stats).clamp(0, 999999999);
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
    final title = habit.tracksDuration ? 'Duration' : 'Amount';
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
                : '$animatedRaw ${habit.amountLabel.trim().isEmpty ? 'times' : habit.amountLabel}';

        return _StatCard(
          title: title,
          value: value,
          iconPath: iconPath,
          fullWidth: true,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.iconPath,
    this.fullWidth = false,
  });

  final String title;
  final String value;
  final String iconPath;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: cp.bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: cp.border),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: ShapeDecoration(
              color: cp.field,
              shape: const OvalBorder(),
            ),
            padding: const EdgeInsets.all(7),
            child: SvgPicture.asset(iconPath),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: cp.lightGreyText, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionRatioLeft extends StatefulWidget {
  const _CompletionRatioLeft({required this.percentage});

  final int percentage;

  @override
  State<_CompletionRatioLeft> createState() => _CompletionRatioLeftState();
}

class _CompletionRatioLeftState extends State<_CompletionRatioLeft>
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
      duration: const Duration(milliseconds: 420),
    );
    _animation = AlwaysStoppedAnimation(_currentPercentage.toDouble());
  }

  @override
  void didUpdateWidget(covariant _CompletionRatioLeft oldWidget) {
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
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cp.field,
                shape: BoxShape.circle,
                border: Border.all(width: 1, color: cp.border),
              ),
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(
                'assets/images/new-svg/completion-rate.svg',
                colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$animatedPercentage%',
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Completion rate',
                  style: TextStyle(color: cp.lightGreyText, fontSize: 16),
                ),
              ],
            ),
          ],
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
      duration: const Duration(milliseconds: 420),
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
              widget.label,
              style: TextStyle(color: cp.lightGreyText, fontSize: 13),
            ),
            Text('-', style: TextStyle(color: cp.lightGreyText, fontSize: 13)),
            Text(
              '$animatedPercentage%',
              style: TextStyle(
                color: cp.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }
}
