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

    bool isPerfect(DateTime day) =>
        dayStatuses[_normalize(day)] == DayCompletionStatus.perfect;

    return Row(
      children: List.generate(days.length, (index) {
        final day = days[index];
        final isToday = day == todayNorm;
        final isFuture = day.isAfter(todayNorm);
        final perfect = isPerfect(day);
        final progress = allStats[_normalize(day)] ?? 0;

        // Connectors link two adjacent perfect days (like the calendar).
        final connectsLeft = index > 0 && perfect && isPerfect(days[index - 1]);
        final connectsRight =
            index < days.length - 1 && perfect && isPerfect(days[index + 1]);

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
}
