import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/habit_age.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';
import 'package:habitt/widgets/stats/counter_stat_card.dart';
import 'package:habitt/widgets/habit_details/new/completion_ratio_section.dart';
import 'package:habitt/widgets/stats/stat_card.dart';
import 'package:provider/provider.dart';

class HabitDetailStatsSections extends StatelessWidget {
  const HabitDetailStatsSections({
    super.key,
    required this.habit,
    required this.stats,
    this.currentStreakOverride,
    this.longestStreakOverride,
  });

  final Habit habit;
  final HabitStatsData stats;
  final int? currentStreakOverride;
  final int? longestStreakOverride;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatsGrid(
          habit: habit,
          stats: stats,
          currentStreakOverride: currentStreakOverride,
          longestStreakOverride: longestStreakOverride,
        ),
        const SizedBox(height: 28),
        CompletionRatioSection(stats: stats),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.habit,
    required this.stats,
    this.currentStreakOverride,
    this.longestStreakOverride,
  });

  final Habit habit;
  final HabitStatsData stats;
  final int? currentStreakOverride;
  final int? longestStreakOverride;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isRecalculating =
        context.watch<HabitProvider>().isRecalculatingLongestStreak;

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
                value: currentStreakOverride ?? stats.currentStreak,
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
                value: longestStreakOverride ?? stats.longestStreak,
                formatter:
                    (value) =>
                        value == 1 ? '1 ${loc.day}' : '$value ${loc.days}',
                isLoading: isRecalculating,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // next to the amount / duration total when there is one
        if (habit.tracksAmount || habit.tracksDuration)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _TotalSpentCard(habit: habit, stats: stats)),
                const SizedBox(width: 10),
                Expanded(child: _ageCard(loc)),
              ],
            ),
          )
        else
          _ageCard(loc, fullWidth: true),
      ],
    );
  }

  Widget _ageCard(AppLocalizations loc, {bool fullWidth = false}) {
    return StatCard(
      title: loc.habitAgeCardTitle,
      value: _ageValue(loc, habitAge(stats.createdAt, DateTime.now())),
      iconPath: 'assets/images/new-svg/calendar.svg',
      fullWidth: fullWidth,
    );
  }

  // the exact day count for the first year, then years / months / days
  String _ageValue(AppLocalizations loc, HabitAge age) {
    if (age.isNew) return loc.habitAgeCardNew;
    if (age.years > 0) {
      return loc.habitAgeCardYearsMonthsDays(
        age.years,
        age.months,
        age.extraDays,
      );
    }
    return age.days == 1 ? '1 ${loc.day}' : '${age.days} ${loc.days}';
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

  // sleep is an amount goal in minutes, so its total reads as a duration
  // ("240h") instead of "14400 times"
  static bool _isSleep(Habit habit) =>
      habit.healthMetric == HealthMetricType.sleep;

  static bool _showsDuration(Habit habit) =>
      habit.tracksDuration || _isSleep(habit);

  int _rawValueFor(Habit habit, HabitStatsData stats) {
    if (habit.tracksDuration) {
      return stats.totalDurationCompletedSeconds;
    }
    if (_isSleep(habit)) return stats.totalAmountCompleted * 60;
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
    final showsDuration = _showsDuration(habit);
    final title = showsDuration ? loc.duration : loc.amount;
    final iconPath =
        showsDuration
            ? 'assets/images/new-svg/clock.svg'
            : 'assets/images/new-svg/amount.svg';

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedRaw = _animation.value.round();
        final customSingulars = context.read<StateProvider>().customSingulars;
        final value =
            showsDuration
                ? getDurationString(animatedRaw)
                : '$animatedRaw ${resolveAmountLabelForValue(habit.amountLabel.isEmpty ? loc.times : habit.amountLabel, animatedRaw, loc, customSingulars: customSingulars)}';

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
