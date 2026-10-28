import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/habit_strength_calculator.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:intl/intl.dart';
import 'package:hive_ce/hive.dart';

class HabitWeekdayRate {
  const HabitWeekdayRate({
    required this.weekday,
    required this.label,
    required this.completed,
    required this.scheduled,
  });

  final int weekday;
  final String label;
  final int completed;
  final int scheduled;

  double get rate => scheduled == 0 ? 0 : completed / scheduled;
  int get percentage => (rate * 100).round();
}

/// Completion numbers for one [StatsRange].
class HabitRangeStats {
  const HabitRangeStats({
    required this.completionRatio,
    required this.bestWeekday,
    required this.worstWeekday,
  });

  final double completionRatio;
  final HabitWeekdayRate bestWeekday;
  final HabitWeekdayRate worstWeekday;
}

class HabitStatsData {
  const HabitStatsData({
    required this.habitId,
    required this.createdAt,
    required this.completedCount,
    required this.missedCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalAmountCompleted,
    required this.totalDurationCompletedSeconds,
    required this.rangeStats,
    required this.dailyProgress,
    required this.currentStrength,
    required this.strengthHistory,
    required this.strengthDates,
    required this.actionableInsight,
    required this.strengthDropLast5Days,
    required this.strengthVarianceLast30Days,
  });

  final int habitId;
  final DateTime createdAt;
  final int completedCount;
  final int missedCount;
  final int currentStreak;
  final int longestStreak;
  final int totalAmountCompleted;
  final int totalDurationCompletedSeconds;
  final Map<StatsRange, HabitRangeStats> rangeStats;
  final Map<DateTime, double> dailyProgress;
  final double currentStrength;
  final List<double> strengthHistory;
  // the day each strengthHistory value belongs to, same length and order
  final List<DateTime> strengthDates;
  final HabitStrengthInsight actionableInsight;
  final double strengthDropLast5Days;
  final double strengthVarianceLast30Days;
}

class _RangeTally {
  int scheduled = 0;
  int completed = 0;
  final scheduledByWeekday = <int, int>{
    for (int weekday = 1; weekday <= 7; weekday++) weekday: 0,
  };
  final completedByWeekday = <int, int>{
    for (int weekday = 1; weekday <= 7; weekday++) weekday: 0,
  };

  void add(DateTime day, {required bool completedThatDay}) {
    scheduled += 1;
    scheduledByWeekday[day.weekday] = scheduledByWeekday[day.weekday]! + 1;
    if (completedThatDay) {
      completed += 1;
      completedByWeekday[day.weekday] = completedByWeekday[day.weekday]! + 1;
    }
  }
}

class _HabitStatsCacheEntry {
  const _HabitStatsCacheEntry({
    required this.fingerprint,
    required this.computedDay,
    required this.data,
    required this.locale,
  });

  final String fingerprint;
  final DateTime computedDay;
  final HabitStatsData data;
  final Locale locale;
}

class HabitStatsProvider extends ChangeNotifier {
  final Box<Day> _daysBox = Hive.box<Day>('days');

  HabitProvider? _habitProvider;
  final Map<int, _HabitStatsCacheEntry> _cache = {};
  final Set<int> _dirtyHabitIds = <int>{};
  DateTime _cachedToday = _normalizeDate(DateTime.now());

  void attachHabitProvider(HabitProvider provider) {
    _habitProvider = provider;
  }

  void invalidateHabit(int habitId) {
    _dirtyHabitIds.add(habitId);
    notifyListeners();
  }

  void removeHabit(int habitId) {
    _cache.remove(habitId);
    _dirtyHabitIds.remove(habitId);
    notifyListeners();
  }

  void clearAll() {
    _cache.clear();
    _dirtyHabitIds.clear();
    notifyListeners();
  }

  HabitStatsData statsForHabit(Habit habit, {Locale? locale}) {
    _refreshDayBoundaryIfNeeded();

    final fingerprint = _buildFingerprint(habit);
    final resolvedLocale =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    final cached = _cache[habit.id];

    if (cached != null &&
        !_dirtyHabitIds.contains(habit.id) &&
        cached.fingerprint == fingerprint &&
        cached.computedDay == _cachedToday &&
        cached.locale.languageCode == resolvedLocale.languageCode) {
      return cached.data;
    }

    final computed = _computeStats(habit, locale: resolvedLocale);
    _cache[habit.id] = _HabitStatsCacheEntry(
      fingerprint: fingerprint,
      computedDay: _cachedToday,
      data: computed,
      locale: resolvedLocale,
    );
    _dirtyHabitIds.remove(habit.id);

    return computed;
  }

  void _refreshDayBoundaryIfNeeded() {
    final today = _normalizeDate(DateTime.now());
    if (_cachedToday == today) {
      return;
    }

    _cachedToday = today;
    _cache.clear();
    _dirtyHabitIds.clear();
    notifyListeners();
  }

  HabitStatsData _computeStats(Habit habit, {Locale? locale}) {
    final today = _cachedToday;
    final resolvedLocale =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;

    final tallies = {
      for (final range in StatsRange.values) range: _RangeTally(),
    };

    int completedCount = 0;
    int missedCount = 0;
    int totalAmountCompleted = 0;
    int totalDurationCompletedSeconds = 0;

    final progressByDay = <DateTime, double>{};
    final strengthEntries = <HabitEntry>[];

    DateTime? earliestDayWithHabit;

    for (final day in _daysBox.values) {
      final dayDate = _normalizeDate(day.date);
      if (dayDate.isAfter(today)) {
        continue;
      }

      final dayHabit = _findHabitInDay(day, habit.id);
      if (dayHabit == null) {
        continue;
      }

      if (dayHabit.isDeleted == true) {
        continue;
      }

      earliestDayWithHabit =
          earliestDayWithHabit == null || dayDate.isBefore(earliestDayWithHabit)
              ? dayDate
              : earliestDayWithHabit;

      progressByDay[dayDate] = _progressValue(dayHabit);

      // An incomplete today isn't a miss yet — the user still has the rest of
      // the day to log it. It would drag strength, the missed count and the
      // completion rates down at the start of the day, so only count today once
      // the habit is completed.
      final countsAsOutcome =
          !dayDate.isAtSameMomentAs(today) || dayHabit.completed;
      if (countsAsOutcome) {
        strengthEntries.add(_toHabitEntry(dayDate, dayHabit));

        if (dayHabit.completed) {
          completedCount += 1;
        } else {
          missedCount += 1;
        }
      }

      totalAmountCompleted += dayHabit.amountCompleted;
      totalDurationCompletedSeconds += dayHabit.durationCompleted;

      if (!countsAsOutcome) continue;

      for (final range in StatsRange.values) {
        final start = range.startFor(today);
        if (start == null || _isWithinRange(dayDate, start, today)) {
          tallies[range]!.add(dayDate, completedThatDay: dayHabit.completed);
        }
      }
    }

    final createdAt = _resolveCreatedAt(
      habit: habit,
      earliestDayWithHabit: earliestDayWithHabit,
      fallback: today,
    );

    final rangeStats = {
      for (final range in StatsRange.values)
        range: _resolveRangeStats(tallies[range]!, resolvedLocale),
    };
    // the calculator walks entries oldest first; sort here so the dates match
    strengthEntries.sort((a, b) => a.date.compareTo(b.date));
    final strengthResult = HabitStrengthCalculator.calculate(strengthEntries);

    return HabitStatsData(
      habitId: habit.id,
      createdAt: createdAt,
      completedCount: completedCount,
      missedCount: missedCount,
      currentStreak: habit.streak,
      longestStreak: habit.longestStreak,
      totalAmountCompleted: totalAmountCompleted,
      totalDurationCompletedSeconds: totalDurationCompletedSeconds,
      rangeStats: rangeStats,
      dailyProgress: progressByDay,
      currentStrength: strengthResult.currentStrength,
      strengthHistory: strengthResult.strengthHistory,
      strengthDates: [for (final entry in strengthEntries) entry.date],
      actionableInsight: strengthResult.actionableInsight,
      strengthDropLast5Days: strengthResult.recentDropFraction,
      strengthVarianceLast30Days: strengthResult.varianceLast30Days,
    );
  }

  static HabitEntry _toHabitEntry(DateTime dayDate, Habit dayHabit) {
    if (dayHabit.tracksAmount) {
      if (dayHabit.amount <= 0) {
        return HabitEntry(
          date: dayDate,
          goal: 1,
          actual: dayHabit.completed ? 1 : 0,
        );
      }
      return HabitEntry(
        date: dayDate,
        goal: dayHabit.amount.toDouble(),
        actual: dayHabit.amountCompleted.toDouble(),
      );
    }

    if (dayHabit.tracksDuration) {
      if (dayHabit.duration <= 0) {
        return HabitEntry(
          date: dayDate,
          goal: 1,
          actual: dayHabit.completed ? 1 : 0,
        );
      }
      return HabitEntry(
        date: dayDate,
        goal: dayHabit.duration.toDouble(),
        actual: dayHabit.durationCompleted.toDouble(),
      );
    }

    return HabitEntry(
      date: dayDate,
      goal: 1,
      actual: dayHabit.completed ? 1 : 0,
    );
  }

  HabitRangeStats _resolveRangeStats(_RangeTally tally, Locale locale) {
    HabitWeekdayRate pick({required bool pickBest}) => _resolveWeekdayRate(
      completedByWeekday: tally.completedByWeekday,
      scheduledByWeekday: tally.scheduledByWeekday,
      pickBest: pickBest,
      locale: locale,
    );

    return HabitRangeStats(
      completionRatio:
          tally.scheduled == 0 ? 0.0 : tally.completed / tally.scheduled,
      bestWeekday: pick(pickBest: true),
      worstWeekday: pick(pickBest: false),
    );
  }

  HabitWeekdayRate _resolveWeekdayRate({
    required Map<int, int> completedByWeekday,
    required Map<int, int> scheduledByWeekday,
    required bool pickBest,
    required Locale locale,
  }) {
    int? targetWeekday;
    double? targetRate;
    int? targetScheduled;

    for (int weekday = 1; weekday <= 7; weekday++) {
      final scheduled = scheduledByWeekday[weekday] ?? 0;
      if (scheduled == 0) {
        continue;
      }

      final completed = completedByWeekday[weekday] ?? 0;
      final rate = completed / scheduled;

      if (targetWeekday == null) {
        targetWeekday = weekday;
        targetRate = rate;
        targetScheduled = scheduled;
        continue;
      }

      final currentRate = targetRate ?? 0;
      final currentScheduled = targetScheduled ?? 0;

      final isBetter =
          pickBest
              ? rate > currentRate ||
                  (rate == currentRate && scheduled > currentScheduled)
              : rate < currentRate ||
                  (rate == currentRate && scheduled > currentScheduled);

      if (isBetter) {
        targetWeekday = weekday;
        targetRate = rate;
        targetScheduled = scheduled;
      }
    }

    if (targetWeekday == null) {
      return const HabitWeekdayRate(
        weekday: 1,
        label: '-',
        completed: 0,
        scheduled: 0,
      );
    }

    return HabitWeekdayRate(
      weekday: targetWeekday,
      label: _weekdayName(targetWeekday, locale),
      completed: completedByWeekday[targetWeekday] ?? 0,
      scheduled: scheduledByWeekday[targetWeekday] ?? 0,
    );
  }

  DateTime _resolveCreatedAt({
    required Habit habit,
    required DateTime? earliestDayWithHabit,
    required DateTime fallback,
  }) {
    final habitCreated = _normalizeDate(habit.createdAt);

    if (earliestDayWithHabit != null) {
      return habitCreated.isBefore(earliestDayWithHabit)
          ? habitCreated
          : earliestDayWithHabit;
    }

    return habitCreated.isBefore(fallback) ? habitCreated : fallback;
  }

  Habit? _findHabitInDay(Day day, int habitId) {
    for (final habit in day.habits) {
      if (habit.id == habitId) {
        return habit;
      }
    }
    return null;
  }

  String _buildFingerprint(Habit habit) {
    int latestTimestamp = 0;
    for (final value in habit.timestamps.values) {
      final millis = value.toUtc().millisecondsSinceEpoch;
      if (millis > latestTimestamp) {
        latestTimestamp = millis;
      }
    }

    final hasProviderState = _habitProvider != null;

    return [
      habit.id,
      latestTimestamp,
      habit.scheduleType.name,
      habit.weeklyTarget,
      habit.monthlyTarget,
      habit.customIntervalDays,
      habit.showIfMissed,
      habit.selectedDaysAWeek.join(','),
      habit.selectedDaysAMonth.join(','),
      habit.completed,
      habit.skipped,
      habit.amount,
      habit.duration,
      habit.amountCompleted,
      habit.durationCompleted,
      habit.createdAt.toUtc().millisecondsSinceEpoch,
      hasProviderState,
    ].join('|');
  }

  static bool _isWithinRange(DateTime day, DateTime start, DateTime end) {
    return !day.isBefore(start) && !day.isAfter(end);
  }

  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String _weekdayName(int weekday, Locale locale) {
    final day = DateTime.utc(2024, 1, weekday);
    return DateFormat.E(locale.languageCode).format(day);
  }

  static double _progressValue(Habit habit) {
    if (habit.completed || habit.skipped) {
      return 1;
    }

    if (habit.tracksAmount) {
      if (habit.amount <= 0) {
        return 0;
      }
      return (habit.amountCompleted / habit.amount).clamp(0.0, 1.0);
    }

    if (habit.tracksDuration) {
      if (habit.duration <= 0) {
        return 0;
      }
      return (habit.durationCompleted / habit.duration).clamp(0.0, 1.0);
    }

    return 0;
  }
}
