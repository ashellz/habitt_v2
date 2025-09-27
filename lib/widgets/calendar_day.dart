import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:provider/provider.dart';

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
      habitsCount = 1;
    }

    final completed = completedHabitsCount == habitsCount && habitsCount > 0;

    final cp = context.watch<ColorProvider>();

    Color getProgressBarColor() {
      final bool isDarkMode = cp.isDarkMode;
      if (isDarkMode) {
        return cp.textColor;
      } else {
        return selected ? cp.colorScheme.strokeColor : cp.textColor;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color:
                    selected
                        ? cp.colorScheme.darkerStandardColor
                        : today
                        ? cp.colorScheme.strokeColor
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    color:
                        cp.isDarkMode
                            ? cp.textColor
                            : selected
                            ? cp.backgroundColor
                            : cp.textColor,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: RotatedBox(
                quarterTurns: -1,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  tween: Tween<double>(
                    begin: 0,
                    end: completedHabitsCount / habitsCount,
                  ),
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      strokeCap: StrokeCap.round,
                      strokeWidth:
                          cp.isDarkMode
                              ? 2
                              : selected
                              ? 3
                              : 2,
                      value: value,
                      color: getProgressBarColor(),
                      backgroundColor: Colors.transparent,
                    );
                  },
                ),
              ),
            ),
            if (completed)
              Transform.translate(
                offset: const Offset(5, 5),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: SvgPicture.asset("assets/images/svg/check.svg"),
                ),
              ),
            if (DateTime(date.year, date.month, date.day) == dateJoined)
              Transform.translate(
                offset: const Offset(7, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: double.infinity,
                    width: 1,
                    color: cp.colorScheme.strokeColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
