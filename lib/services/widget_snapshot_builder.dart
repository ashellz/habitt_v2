import 'dart:ui' show Color;

import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/app_theme.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/streak_health.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/habit_progress.dart';
import 'package:habitt/util/streak_praise.dart';
import 'package:intl/intl.dart';

/// Builds the JSON document the home screen widgets render (see
/// docs/home_widgets.md for every field). Pure: everything it needs comes in
/// through [WidgetSnapshotInput], so it is unit tested without providers.
///
/// The widgets hold no habit logic. Everything they show, including what
/// "tomorrow" looks like if today ends as it is now, is decided here.
class WidgetSnapshotBuilder {
  /// Bumped when a field changes meaning; the native readers check it.
  static const int version = 1;

  /// Habit category ids (see CategoryProvider).
  static const int anyTime = 1, morning = 2, afternoon = 3, evening = 4;
  static const int maxUpNextRows = 3;

  static Map<String, dynamic> build(WidgetSnapshotInput input) {
    final today = _dateOnly(input.now);
    final tomorrow = today.add(const Duration(days: 1));
    final loc = input.loc;

    final todayStatus = input.statuses[today] ?? DayCompletionStatus.none;
    final todayPerfect = todayStatus == DayCompletionStatus.perfect;

    // today: the app's own streak (which leaves today out) plus today if it
    // is already perfect, exactly like the home page streak card
    final todayHealth = resolveStreakHealth(
      streak: input.streak,
      tailMisses: input.tailMisses,
      todayIsSecure: todayPerfect,
    );
    final todayStreak = _streakBlock(
      input,
      day: today,
      count: input.streak + (todayPerfect ? 1 : 0),
      health: todayHealth,
      perfectToday: todayPerfect,
      hasProgressToday: todayStatus == DayCompletionStatus.partial,
    );

    // tomorrow: as if today ends exactly as it is now
    final throughToday =
        (input.statuses.entries.where((e) => !e.key.isAfter(today)).toList()
              ..sort((a, b) => a.key.compareTo(b.key)))
            .map((e) => e.value)
            .toList();
    final next = computeCurrentStreak(throughToday);
    final tomorrowStreak = _streakBlock(
      input,
      day: tomorrow,
      count: next.streak,
      health: resolveStreakHealth(
        streak: next.streak,
        tailMisses: next.tailMisses,
        todayIsSecure: false,
      ),
      perfectToday: false,
      hasProgressToday: false,
    );

    return {
      'v': version,
      'generatedAt': input.now.toIso8601String(),
      'dayKey': _dayKey(today),
      'nextDayStartsAt': tomorrow.toIso8601String(),
      'theme': {
        'light': {'accent': _hex(input.theme.light.main)},
        'dark': {'accent': _hex(input.theme.dark.main)},
      },
      'strings': {
        'dayStreak': '${loc.day} ${loc.streak}',
        'daysStreak': '${loc.days} ${loc.streak}',
        'dayComplete': loc.widgetDayComplete,
        'dayCompleteBody': loc.widgetDayCompleteBody,
        'nothingToday': loc.widgetNothingToday,
      },
      'today': _dayBlock(input, input.todayHabits, todayStreak),
      'tomorrow': _dayBlock(input, input.tomorrowHabits, tomorrowStreak),
    };
  }

  static Map<String, dynamic> _dayBlock(
    WidgetSnapshotInput input,
    List<Habit> habits,
    Map<String, dynamic> streak,
  ) {
    final rows = [for (final h in habits) _habitRow(input, h)];
    final counted = rows.where((r) => r['optional'] != true).toList();
    final done = counted.where((r) => r['state'] == 'done').length;
    final perfect = counted.isNotEmpty && done == counted.length;

    return {
      'habits': rows,
      'ring': [for (final r in counted) r['id']],
      'done': done,
      'total': counted.length,
      'perfect': perfect,
      'streak': streak,
      'upNext': {
        'morning': perfect ? null : _upNext(input, rows, morning),
        'afternoon': perfect ? null : _upNext(input, rows, afternoon),
        'evening': perfect ? null : _upNext(input, rows, evening),
      },
    };
  }

  static Map<String, dynamic> _habitRow(WidgetSnapshotInput input, Habit h) {
    final progress = habitProgressValue(h);
    final done = h.completed || h.skipped;
    return {
      'id': h.id,
      'emoji': h.iconPath,
      'name': h.resolvedName(input.localeCode),
      'category': h.categoryId,
      'optional': h.optional,
      'progress': double.parse(progress.toStringAsFixed(3)),
      'progressText': habitProgressText(
        h,
        loc: input.loc,
        customSingulars: input.customSingulars,
        formatTime: input.formatTime,
      ),
      'state': done ? 'done' : (progress > 0 ? 'partial' : 'todo'),
      'canLog': h.hasTrackingType,
    };
  }

  /// What Up next shows while [part] is the current part of the day: the
  /// first section with something left to do, trying [part], then Any time,
  /// then the later parts, then the earlier ones. At most [maxUpNextRows]
  /// rows in app order; when the section is longer, done habits make room
  /// first.
  static Map<String, dynamic>? _upNext(
    WidgetSnapshotInput input,
    List<Map<String, dynamic>> rows,
    int part,
  ) {
    final order = [
      part,
      anyTime,
      for (final p in [morning, afternoon, evening])
        if (p > part) p,
      for (final p in [morning, afternoon, evening])
        if (p < part) p,
    ];
    for (final category in order) {
      final section = rows.where((r) => r['category'] == category).toList();
      if (!section.any((r) => r['state'] != 'done')) continue;
      while (section.length > maxUpNextRows) {
        final firstDone = section.indexWhere((r) => r['state'] == 'done');
        section.removeAt(firstDone >= 0 ? firstDone : section.length - 1);
      }
      return {
        'label': _categoryName(input.loc, category),
        'icon': category == anyTime ? 'anyTime' : _partKey(category),
        'habits': [for (final r in section) r['id']],
      };
    }
    return null;
  }

  static Map<String, dynamic> _streakBlock(
    WidgetSnapshotInput input, {
    required DateTime day,
    required int count,
    required StreakHealth health,
    required bool perfectToday,
    required bool hasProgressToday,
  }) {
    final week = <Map<String, dynamic>>[];
    final letter = DateFormat.EEEEE(input.localeCode);
    for (int i = 6; i >= 0; i--) {
      final d = day.subtract(Duration(days: i));
      final isDay = i == 0;
      final status = input.statuses[d];
      final String s;
      if (isDay) {
        s = perfectToday ? 'perfect' : 'today';
      } else {
        s = switch (status) {
          DayCompletionStatus.perfect => 'perfect',
          DayCompletionStatus.partial => 'partial',
          DayCompletionStatus.miss => 'miss',
          _ => 'none',
        };
      }
      week.add({
        'label': letter.format(d),
        's': s,
        'p': double.parse((input.dayProgress[d] ?? 0).toStringAsFixed(3)),
      });
    }

    final String line;
    if (health == StreakHealth.dormant) {
      line = input.loc.widgetStartStreak;
    } else {
      final options = streakCopyOptions(
        input.loc,
        health: health,
        hasProgressToday: hasProgressToday,
      );
      // one pick per day, so the wording does not change on every refresh
      line = options[_epochDay(day) % options.length];
    }

    return {
      'count': count,
      'health': health.name,
      'perfectToday': perfectToday,
      'line': line,
      'week': week,
    };
  }

  static String _categoryName(AppLocalizations loc, int id) => switch (id) {
    morning => loc.morning,
    afternoon => loc.afternoon,
    evening => loc.evening,
    _ => loc.anyTime,
  };

  static String _partKey(int id) => switch (id) {
    morning => 'morning',
    afternoon => 'afternoon',
    _ => 'evening',
  };

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _epochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Everything [WidgetSnapshotBuilder.build] reads.
class WidgetSnapshotInput {
  WidgetSnapshotInput({
    required this.now,
    required this.todayHabits,
    required this.tomorrowHabits,
    required this.statuses,
    required this.dayProgress,
    required this.streak,
    required this.tailMisses,
    required this.loc,
    required this.localeCode,
    required this.customSingulars,
    required this.formatTime,
    required this.theme,
  });

  final DateTime now;

  /// Today's habits in app order, as the home page lists them.
  final List<Habit> todayHabits;

  /// Habits scheduled tomorrow, with no progress, in app order.
  final List<Habit> tomorrowHabits;

  /// Per-day status for every tracked day, today included (live).
  final Map<DateTime, DayCompletionStatus> statuses;

  /// Per-day progress 0–1 for every tracked day, today included.
  final Map<DateTime, double> dayProgress;

  /// The perfect-days streak and its tail misses, not counting today.
  final int streak;
  final int tailMisses;

  final AppLocalizations loc;
  final String localeCode;
  final Map<String, String> customSingulars;

  /// Minutes since midnight → localized clock time.
  final String Function(int minutes) formatTime;
  final AppTheme theme;
}
