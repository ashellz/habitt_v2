import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
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
              child: _AnimatedCounterStatCard(
                title: 'Completed',
                iconPath: 'assets/images/new-svg/completed.svg',
                value: stats.completedCount,
                formatter: (value) => '$value',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AnimatedCounterStatCard(
                title: 'Skipped',
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
              child: _AnimatedCounterStatCard(
                title: 'Current streak',
                iconPath: 'assets/images/new-svg/streak.svg',
                value: stats.currentStreak,
                formatter: (value) => value == 1 ? '1 day' : '$value days',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AnimatedCounterStatCard(
                title: 'Longest streak',
                iconPath: 'assets/images/new-svg/longest-streak.svg',
                value: stats.longestStreak,
                formatter: (value) => value == 1 ? '1 day' : '$value days',
              ),
            ),
          ],
        ),
        if (habit.tracksAmount || habit.tracksDuration) ...[
          const SizedBox(height: 10),
          _AnimatedTotalSpentCard(habit: habit, stats: stats),
        ],
      ],
    );
  }
}

class _AnimatedCounterStatCard extends StatefulWidget {
  const _AnimatedCounterStatCard({
    required this.title,
    required this.iconPath,
    required this.value,
    required this.formatter,
  });

  final String title;
  final String iconPath;
  final int value;
  final String Function(int value) formatter;

  @override
  State<_AnimatedCounterStatCard> createState() =>
      _AnimatedCounterStatCardState();
}

class _AnimatedCounterStatCardState extends State<_AnimatedCounterStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late int _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(0, 999999999);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = AlwaysStoppedAnimation(_currentValue.toDouble());
  }

  @override
  void didUpdateWidget(covariant _AnimatedCounterStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nextValue = widget.value.clamp(0, 999999999);
    if (nextValue == _currentValue) {
      return;
    }

    _animation = Tween<double>(
      begin: _currentValue.toDouble(),
      end: nextValue.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _currentValue = nextValue;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedValue = _animation.value.round();

        return _StatCard(
          title: widget.title,
          value: widget.formatter(animatedValue),
          iconPath: widget.iconPath,
          cloudProgress: _controller.value,
        );
      },
    );
  }
}

class _AnimatedTotalSpentCard extends StatefulWidget {
  const _AnimatedTotalSpentCard({required this.habit, required this.stats});

  final Habit habit;
  final HabitStatsData stats;

  @override
  State<_AnimatedTotalSpentCard> createState() =>
      _AnimatedTotalSpentCardState();
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
  void didUpdateWidget(covariant _AnimatedTotalSpentCard oldWidget) {
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
            : '$animatedRaw ${resolveAmountLabelForValue(habit.amountLabel.isEmpty ? 'times' : habit.amountLabel, animatedRaw)}';

        return _StatCard(
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.iconPath,
    this.fullWidth = false,
    this.cloudProgress,
  });

  final String title;
  final String value;
  final String iconPath;
  final bool fullWidth;
  final double? cloudProgress;

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
                _ValueBlurCloud(
                  progress: cloudProgress,
                  borderRadius: BorderRadius.circular(8),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
      duration: const Duration(milliseconds: 650),
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
                _ValueBlurCloud(
                  progress: _controller.value,
                  borderRadius: BorderRadius.circular(10),
                  child: Text(
                    '$animatedPercentage%',
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
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
              widget.label,
              style: TextStyle(color: cp.lightGreyText, fontSize: 13),
            ),
            Text('-', style: TextStyle(color: cp.lightGreyText, fontSize: 13)),
            _ValueBlurCloud(
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

class _ValueBlurCloud extends StatelessWidget {
  const _ValueBlurCloud({
    required this.child,
    this.progress,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final double? progress;
  final BorderRadius borderRadius;

  double _opacityFor(double t) {
    if (t <= 0 || t >= 0.58) {
      return 0;
    }
    if (t < 0.16) {
      return (t / 0.16) * 0.85;
    }
    return (1 - ((t - 0.16) / 0.42)).clamp(0.0, 1.0) * 0.85;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final t = progress ?? 1;
    final opacity = _opacityFor(t);
    final sigma = 1 + (opacity * 5);

    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (opacity > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          cp.field.withValues(alpha: opacity * 0.95),
                          cp.field.withValues(alpha: opacity * 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.65, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
