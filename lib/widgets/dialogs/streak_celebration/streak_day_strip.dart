import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:provider/provider.dart';

/// Non-interactive 7-day strip centered on today (today in the middle, three
/// days on each side). Mirrors the colors/connectors of [StreakCalendar] but as
/// a fixed, tap-proof row for the streak celebration dialog.
class StreakDayStrip extends StatelessWidget {
  const StreakDayStrip({
    super.key,
    required this.dayStatuses,
    required this.allStats,
    this.today,
  });

  final Map<DateTime, DayCompletionStatus> dayStatuses;
  final Map<DateTime, double> allStats;
  final DateTime? today;

  static DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final todayNorm = _normalize(today ?? DateTime.now());

    // 7 days: three before today, today, three after.
    final days = List<DateTime>.generate(
      7,
      (i) => todayNorm.add(Duration(days: i - 3)),
    );

    final normalizedStatuses = {
      for (final entry in dayStatuses.entries)
        _normalize(entry.key): entry.value,
    };

    // Connectors follow the same tolerated-miss runs as the streak calendar:
    // any day bridged inside an unbroken run connects to its neighbours, even
    // if that day itself isn't perfect (a neutral/partial day or a tolerated
    // miss).
    final connectors = _buildRunConnectors(
      statuses: normalizedStatuses,
      lastDay: days.last,
    );

    return Row(
      children: List.generate(days.length, (index) {
        final day = days[index];
        final isToday = day == todayNorm;
        final isFuture = day.isAfter(todayNorm);
        final perfect = normalizedStatuses[day] == DayCompletionStatus.perfect;
        final progress = allStats[day] ?? 0;

        final flags = connectors[day];
        final connectsLeft = flags?.left ?? false;
        final connectsRight = flags?.right ?? false;

        late Color fillColor;
        late Color borderColor;
        late Color textColor;

        if (isFuture) {
          fillColor = Colors.transparent;
          borderColor = Colors.transparent;
          textColor = cp.text;
        } else if (perfect) {
          fillColor = isToday ? cp.orange300 : cp.bg;
          borderColor = isToday ? cp.orange300 : cp.orange200;
          textColor = isToday ? Colors.white : cp.text;
        } else if (progress > 0) {
          fillColor = cp.bg;
          borderColor = cp.disabled;
          textColor = cp.text;
        } else {
          fillColor = cp.bg;
          borderColor = cp.bg;
          textColor = cp.text;
        }

        return Expanded(
          child: SizedBox(
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Connector halves behind the circle.
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          color:
                              connectsLeft ? cp.orange100 : Colors.transparent,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 38,
                          color:
                              connectsRight ? cp.orange100 : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: ShapeDecoration(
                    color: fillColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(width: 1, color: borderColor),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Builds the same tolerated-miss runs the streak calendar uses, then derives
  /// per-day left/right connector flags. A connector exists between two adjacent
  /// days when they are consecutive within an unbroken run — so neutral/partial
  /// days and tolerated misses that don't break the streak still connect.
  static Map<DateTime, ({bool left, bool right})> _buildRunConnectors({
    required Map<DateTime, DayCompletionStatus> statuses,
    required DateTime lastDay,
  }) {
    final flags = <DateTime, ({bool left, bool right})>{};
    if (statuses.isEmpty) return flags;

    // Start from the earliest tracked day so run state (ongoing run, tolerated
    // misses used) is established correctly before reaching the visible window.
    final firstDay = _normalize(
      statuses.keys.reduce((a, b) => a.isBefore(b) ? a : b),
    );

    final runs = <List<DateTime>>[];
    var currentDays = <DateTime>[];
    var hasCompletion = false;
    var toleratedMissesUsed = 0;
    var cursor = firstDay;

    void flushRun() {
      // Trim trailing non-perfect days (tolerated misses / neutral skips that
      // never bridged back to a completion).
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
