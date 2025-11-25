import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/color_contrast.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class CalendarDay extends StatelessWidget {
  const CalendarDay({
    super.key,
    required this.date,
    this.selected = false,
    this.today = false,
  });

  final DateTime date;
  final bool selected;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final List<Habit> habits = context.watch<HabitProvider>().getHabitsFromDay(
      date,
    );

    int habitsCount = habits.length;
    int completedHabitsCount = habits.where((h) => h.completed).length;

    final dateJoinedLong = context.watch<HabitProvider>().dateJoined;
    final dateJoined = DateTime(
      dateJoinedLong.year,
      dateJoinedLong.month,
      dateJoinedLong.day,
    );

    if (habits.isEmpty ||
        date.isBefore(dateJoined) ||
        date.isAfter(DateTime.now())) {
      habitsCount = 0;
    }

    final tp = context.watch<ThemeProvider>();

    final completedColor = tp.successColor;
    final uncompletedColor = tp.surfaceColor;

    Color progressColor({
      required Color start, // e.g., incomplete (dark grey)
      required Color end, // e.g., complete (green)
      required int completed,
      required int total,
    }) {
      if (total <= 0) return start;
      final t = (completed / total).clamp(0.0, 1.0);
      return Color.lerp(start, end, t)!;
    }

    bool isBeforeDateJoined() {
      if (DateTime(date.year, date.month, date.day).isBefore(dateJoined)) {
        return true;
      }
      return false;
    }

    Color getBorderColor(Color color) {
      // color: selected ? color.darken() : Colors.transparent,
      if (selected) {
        switch (tp.isDark) {
          case true:
            return color.lighten(20);
          case false:
            return color.darken(20);
        }
      } else {
        return Colors.transparent;
      }
    }

    final color = progressColor(
      start: uncompletedColor,
      end: completedColor,
      completed: completedHabitsCount,
      total: habitsCount,
    );

    return Padding(
      padding: const EdgeInsets.all(6),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(
                  color: getBorderColor(color),
                  width: selected ? 1 : 0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    color:
                        isBeforeDateJoined()
                            ? tp.mutedTextColor
                            : bestContrastingOn(
                              color,
                              light: Colors.white,
                              dark: tp.primaryTextColor,
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
