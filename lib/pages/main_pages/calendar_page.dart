import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:habitt/widgets/default/blur_fade.dart';
import 'package:habitt/widgets/habit_details/strength_chart.dart';
import 'package:habitt/widgets/stats/completion_bar_chart.dart';
import 'package:habitt/widgets/stats/completion_rate.dart';
import 'package:habitt/widgets/stats/completion_ratio_text.dart';
import 'package:habitt/widgets/stats/consistency_calendar.dart';
import 'package:habitt/widgets/stats/counter_stat_card.dart';
import 'package:habitt/widgets/stats/streak_calendar.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key, this.isActive = true});

  final bool isActive;

  static Widget demo() => const _DemoCalendarBody();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final sp = context.watch<StatsProvider>();
    final hp = context.watch<HabitProvider>();
    final allStats = sp.getAllDaysProgress(hp);
    final dayStatuses = sp.getDayCompletionStatuses(hp);

    final streak = sp.perfectDaysStreak;
    final longestStreak = sp.longestPerfectDaysStreak;

    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: RefreshIndicator(
        color: cp.main,
        onRefresh: () async {
          context.read<StatsProvider>().refreshStats(force: true);
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text(
                loc.calendar,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: cp.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              StreakCalendarSection(
                streak: streak,
                longestStreak: longestStreak,
                allStats: allStats,
                dayStatuses: dayStatuses,
                isActive: isActive,
                isLoading: hp.isRecalculatingLongestStreak,
              ),
              SizedBox(height: 32),
              CompletionRatio(cp: cp),
              SizedBox(height: 32),
              ConsistencyCalendar(allStats: allStats),
              SizedBox(height: 145),
            ],
          ),
        ),
      ),
    );
  }
}

class CompletionRatio extends StatefulWidget {
  const CompletionRatio({
    super.key,
    required this.cp,
    this.overrideRatesByDay,
    this.today,
    this.overridePercentage,
  });

  final ColorProvider cp;
  final List<double>? overrideRatesByDay;
  final DateTime? today;
  final int? overridePercentage;

  @override
  State<CompletionRatio> createState() => _CompletionRatioState();
}

class _CompletionRatioState extends State<CompletionRatio> {
  // what the selector shows, it moves the moment it is tapped
  StatsRange _range = StatsRange.week;
  // what the number and chart show, they follow a frame later
  StatsRange _shownRange = StatsRange.week;

  // ALL needs at least this many tracked days for a weekly trend line,
  // shorter histories get daily bars like 30D
  static const int _minDaysForTrend = 31;

  @override
  Widget build(BuildContext context) {
    final cp = widget.cp;

    // the demo passes its own numbers and never reads the providers
    final percentage =
        widget.overridePercentage ??
        context.watch<StatsProvider>().getCompletionRate(_shownRange);

    return Column(
      spacing: 20,
      children: [
        CompletionRatioText(range: _range, onRangeChanged: _onRangeChanged),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: cp.habitBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Column(
            spacing: 20,
            children: [
              CompletionRate(percentage: percentage),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: BlurFade.transition,
                  child: KeyedSubtree(
                    key: ValueKey(_shownRange),
                    child: _chart(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // the selector updates in this frame, the chart in the next one, so the tap
  // never waits on the new chart being built
  void _onRangeChanged(StatsRange range) {
    setState(() => _range = range);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _shownRange == _range) return;
      setState(() => _shownRange = _range);
    });
  }

  // ─── Chart ────────────────────────────────────────────
  // 7D and 30D: a bar per day. ALL: a weekly trend line, or daily bars while
  // the history is too short for one.
  Widget _chart(BuildContext context) {
    final override = widget.overrideRatesByDay;
    if (override != null) {
      return CompletionBarChart(rates: override, today: widget.today);
    }

    final sp = context.watch<StatsProvider>();
    final hp = context.watch<HabitProvider>();
    final days = _shownRange.days ?? _trackedDays(sp);

    if (days != null) {
      return CompletionBarChart(rates: sp.getCompletionRateByDay(hp, days));
    }

    final weekly = sp.getWeeklyCompletionRates(hp);
    // a line needs two points on a real time axis
    if (weekly.dates.length < 2) {
      return CompletionBarChart(rates: sp.getCompletionRateByDay(hp, 30));
    }

    return StrengthChart(
      dates: weekly.dates,
      values: weekly.values,
      from: weekly.dates.first,
      to: weekly.dates.last,
    );
  }

  // days from the first tracked one to today (at least a week), null once
  // there are enough for the trend line
  int? _trackedDays(StatsProvider sp) {
    final first = sp.firstTrackedDay;
    if (first == null) return 7;
    final now = DateTime.now();
    final days =
        DateTime.utc(
          now.year,
          now.month,
          now.day,
        ).difference(DateTime.utc(first.year, first.month, first.day)).inDays +
        1;
    if (days >= _minDaysForTrend) return null;
    return max(days, 7);
  }
}

class StreakCalendarSection extends StatelessWidget {
  const StreakCalendarSection({
    super.key,
    required this.streak,
    required this.longestStreak,
    required this.allStats,
    required this.dayStatuses,
    this.today,
    this.isActive = true,
    this.isLoading = false,
  });

  final int streak;
  final int longestStreak;
  final Map<DateTime, double> allStats;
  final Map<DateTime, DayCompletionStatus> dayStatuses;
  final DateTime? today;
  final bool isActive;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      spacing: 20,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CounterStatCard(
                  title: loc.currentStreak,
                  iconPath: 'assets/images/new-svg/streak.svg',
                  value: streak,
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
                  value: longestStreak,
                  formatter:
                      (value) =>
                          value == 1 ? '1 ${loc.day}' : '$value ${loc.days}',
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ),
        StreakCalendar(
          allStats: allStats,
          dayStatuses: dayStatuses,
          today: today,
          isActive: isActive,
        ),
      ],
    );
  }
}

class _DemoCalendarBody extends StatelessWidget {
  const _DemoCalendarBody();

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    final realNow = DateTime.now();
    final demoToday = DateTime(realNow.year, realNow.month, 9);
    final seeded = Random(realNow.year * 100 + realNow.month);

    const completedDays = {2, 5, 7, 8, 9};

    final allStats = <DateTime, double>{};
    for (int d = 1; d <= 9; d++) {
      final date = DateTime(realNow.year, realNow.month, d);
      if (completedDays.contains(d)) {
        allStats[date] = 1.0;
      } else {
        allStats[date] = 0.15 + seeded.nextDouble() * 0.7;
      }
    }

    final dayStatuses = <DateTime, DayCompletionStatus>{
      for (int d = 1; d <= 9; d++)
        DateTime(realNow.year, realNow.month, d):
            completedDays.contains(d)
                ? DayCompletionStatus.perfect
                : DayCompletionStatus.miss,
    };

    final completionRateLastWeek = List<double>.generate(7, (index) {
      final dayOfMonth = 3 + index;
      if (completedDays.contains(dayOfMonth)) {
        return 100.0;
      }
      return 20.0 + seeded.nextDouble() * 50.0;
    });

    const streak = 3;
    const longestStreak = 10;
    const completionPercentage = 71;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: ListView(
          children: [
            Text(
              loc.calendar,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: cp.text,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            StreakCalendarSection(
              streak: streak,
              longestStreak: longestStreak,
              allStats: allStats,
              dayStatuses: dayStatuses,
              today: demoToday,
            ),
            const SizedBox(height: 32),
            CompletionRatio(
              cp: cp,
              overrideRatesByDay: completionRateLastWeek,
              today: demoToday,
              overridePercentage: completionPercentage,
            ),
            const SizedBox(height: 32),
            ConsistencyCalendar(allStats: allStats, today: demoToday),
            const SizedBox(height: 145),
          ],
        ),
      ),
    );
  }
}
