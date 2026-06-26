import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:provider/provider.dart';

class StreakDayStrip extends StatelessWidget {
  const StreakDayStrip({
    super.key,
    required this.dayStatuses,
    required this.allStats,
    required this.progress,
    this.today,
  });

  final Map<DateTime, DayCompletionStatus> dayStatuses;
  final Map<DateTime, double> allStats;

  /// Curved 0 → 1 progress driving the slide, hero fill grow and connector fade.
  final Animation<double> progress;
  final DateTime? today;

  static DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Eased 0 → 1 value for the hero fill / connector, lagging the slide so the
  /// hero ignites as it settles into the centre.
  double _heroReveal(double p) => ((p - 0.45) / 0.55).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final todayNorm = _normalize(today ?? DateTime.now());
    // The celebrated day is always yesterday.
    final hero = todayNorm.subtract(const Duration(days: 1));

    // Render 8 days [hero-4 .. hero+3]; the visible 7-wide window slides from
    // [hero-4 .. hero+2] (hero just right of centre) to [hero-3 .. hero+3]
    // (hero centred) as progress goes 0 → 1.
    final days = List<DateTime>.generate(
      8,
      (i) => _normalize(hero.add(Duration(days: i - 4))),
    );

    final normalizedStatuses = {
      for (final entry in dayStatuses.entries)
        _normalize(entry.key): entry.value,
    };

    final connectors = _buildRunConnectors(
      statuses: normalizedStatuses,
      lastDay: days.last,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final cellW = maxW / 7;
        final circle = math.min(cellW * 0.8, 44.0);

        return SizedBox(
          width: maxW,
          height: circle,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                final p = progress.value;
                final reveal = _heroReveal(p);
                return OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: cellW * 8,
                  child: Transform.translate(
                    offset: Offset(-p * cellW, 0),
                    child: SizedBox(
                      width: cellW * 8,
                      child: Row(
                        children: [
                          for (final day in days)
                            _cell(
                              cp: cp,
                              day: day,
                              hero: hero,
                              todayNorm: todayNorm,
                              cellW: cellW,
                              circle: circle,
                              statuses: normalizedStatuses,
                              connectors: connectors,
                              reveal: reveal,
                              p: p,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _cell({
    required ColorProvider cp,
    required DateTime day,
    required DateTime hero,
    required DateTime todayNorm,
    required double cellW,
    required double circle,
    required Map<DateTime, DayCompletionStatus> statuses,
    required Map<DateTime, ({bool left, bool right})> connectors,
    required double reveal,
    required double p,
  }) {
    final isHero = day == hero;
    final isToday = day == todayNorm;
    final isFuture = day.isAfter(todayNorm);
    final perfect = statuses[day] == DayCompletionStatus.perfect;
    final progressValue = allStats[day] ?? 0;

    final flags = connectors[day];
    var connectsLeft = flags?.left ?? false;
    var connectsRight = flags?.right ?? false;

    // today is as empty for good design
    // if it wasnt empty it would look off
    // because edited days would be after the middle one
    if (isToday) {
      connectsLeft = false;
      connectsRight = false;
    }
    if (isHero) {
      connectsRight = false; // would point at today, same reason as above
    }

    // animating connections for hero and solid for regular days
    final heroLeftSegment = day == hero; // left half of hero
    final heroRightSegment = day == hero.subtract(const Duration(days: 1));

    // most left day removes left connection after animation
    final leftmostFinal = day == hero.subtract(const Duration(days: 3));
    double leftConnOpacity = connectsLeft ? 1.0 : 0.0;
    double rightConnOpacity = connectsRight ? 1.0 : 0.0;
    if (heroLeftSegment) leftConnOpacity = connectsLeft ? reveal : 0.0;
    if (heroRightSegment) rightConnOpacity = connectsRight ? reveal : 0.0;
    if (leftmostFinal) leftConnOpacity = connectsLeft ? (1 - p) : 0.0;

    late Color baseFill;
    late Color baseBorder;
    late Color textColor;

    if (isHero) {
      // solid fill grows from center
      baseFill = cp.bg;
      baseBorder = Color.lerp(cp.orange200, cp.orange300, reveal)!;
      textColor = Color.lerp(cp.text, Colors.white, reveal)!;
    } else if (isFuture || isToday) {
      baseFill = Colors.transparent;
      baseBorder = Colors.transparent;
      textColor = cp.text;
    } else if (perfect) {
      baseFill = cp.bg;
      baseBorder = cp.orange200;
      textColor = cp.text;
    } else if (progressValue > 0) {
      baseFill = cp.bg;
      baseBorder = cp.disabled;
      textColor = cp.text;
    } else {
      baseFill = cp.bg;
      baseBorder = cp.bg;
      textColor = cp.text;
    }

    return SizedBox(
      width: cellW,
      child: Center(
        child: SizedBox(
          width: cellW,
          height: circle,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: circle,
                        color: cp.orange100.withValues(alpha: leftConnOpacity),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: circle,
                        color: cp.orange100.withValues(alpha: rightConnOpacity),
                      ),
                    ),
                  ],
                ),
              ),
              // Base circle (ring / fill).
              Container(
                width: circle,
                height: circle,
                decoration: ShapeDecoration(
                  color: baseFill,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: BorderSide(width: 1, color: baseBorder),
                  ),
                ),
              ),
              // Hero solid fill, growing from the centre.
              if (isHero && reveal > 0)
                Transform.scale(
                  scale: reveal,
                  child: Container(
                    width: circle,
                    height: circle,
                    decoration: ShapeDecoration(
                      color: cp.orange300,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              Text(
                '${day.day}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // same logic for connectors as streak calc
  // exceptions adjusted to fit thsi dialog
  static Map<DateTime, ({bool left, bool right})> _buildRunConnectors({
    required Map<DateTime, DayCompletionStatus> statuses,
    required DateTime lastDay,
  }) {
    final flags = <DateTime, ({bool left, bool right})>{};
    if (statuses.isEmpty) return flags;

    // Start from the earliest tracked day so run state (ongoing run, tolerated
    // misses used) is established correctly before reaching the visible window.
    // this is okay becuase its only done once (on init of this build) and you dont see it anymore
    final firstDay = _normalize(
      statuses.keys.reduce((a, b) => a.isBefore(b) ? a : b),
    );

    final runs = <List<DateTime>>[];
    var currentDays = <DateTime>[];
    var hasCompletion = false;
    var toleratedMissesUsed = 0;
    var cursor = firstDay;

    void flushRun() {
      // removes all bridges/connectors that dont end in a perfect day (that fail)
      // eg. perfect, misssed, missed, missed - originall all missed are assigned a connector
      // this iteration looks for those and removes connectors

      while (currentDays.isNotEmpty &&
          statuses[currentDays.last] != DayCompletionStatus.perfect) {
        currentDays.removeLast();
      }
      if (currentDays.length > 1) {
        runs.add(List<DateTime>.from(currentDays));
      }
      currentDays = [];
    }

    while (!cursor.isAfter(lastDay)) {
      final day = _normalize(cursor);
      final status = statuses[day] ?? DayCompletionStatus.none;
      final isCompleted = status == DayCompletionStatus.perfect;
      final isNeutral =
          status == DayCompletionStatus.partial ||
          status == DayCompletionStatus.none;

      if (!hasCompletion) {
        if (isCompleted) {
          hasCompletion = true;
          toleratedMissesUsed = 0;
          currentDays.add(day);
        }
      } else if (isCompleted) {
        currentDays.add(day);
        toleratedMissesUsed = 0;
      } else if (isNeutral) {
        currentDays.add(day);
      } else if (toleratedMissesUsed < kStreakMissTolerance) {
        currentDays.add(day);
        toleratedMissesUsed++;
      } else {
        flushRun();
        hasCompletion = false;
        toleratedMissesUsed = 0;
      }

      cursor = cursor.add(const Duration(days: 1));
    }
    flushRun();

    for (final run in runs) {
      for (int i = 0; i < run.length - 1; i++) {
        final left = run[i];
        final right = run[i + 1];
        flags[left] = (left: flags[left]?.left ?? false, right: true);
        flags[right] = (left: true, right: flags[right]?.right ?? false);
      }
    }

    return flags;
  }
}
