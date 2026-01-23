import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
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
    final List<Habit> habits =
        selected
            ? context.select<HabitProvider, List<Habit>>(
              (provider) => provider.getHabitsFromDay(date),
            )
            : [];

    final Colorfulness colorfulness =
        context.read<PreferencesProvider>().colorfulness;

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

    bool isBeforeDateJoined() {
      if (DateTime(date.year, date.month, date.day).isBefore(dateJoined)) {
        return true;
      }
      return false;
    }

    Color getBorderColor() {
      double completionRatio = completedHabitsCount / habitsCount;
      Color? color;

      if (completionRatio == 0) {
        color = tp.dangerColor;
      } else if (completionRatio > 0 && completionRatio < 1) {
        color = tp.warningColor;
      } else if (completionRatio == 1) {
        color = tp.successColor;
      }

      if (selected && color == null) {
        return tp.primaryColor;
      }

      return color ?? Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                border: Border.all(
                  color: getBorderColor(),
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
                            : tp.primaryTextColor,
                  ),
                ),
              ),
            ),
            _getCompletionIcon(
              habitsCount,
              completedHabitsCount,
              colorfulness,
              tp,
            ),
          ],
        ),
      ),
    );
  }

  _getCompletionIcon(
    int habitsCount,
    int completedHabitsCount,
    Colorfulness colorfulness,
    ThemeProvider tp,
  ) {
    String? assetPath;
    Color? svgColor;

    resolveAssetPath() {
      if (habitsCount == 0) {
        return null;
      }

      double completionRatio = completedHabitsCount / habitsCount;

      if (completionRatio == 0) {
        svgColor = tp.dangerColor;
        return 'assets/images/svg/incomplete.svg';
      } else if (completionRatio > 0 && completionRatio < 1) {
        return 'assets/images/svg/incomplete.svg';
      } else if (completionRatio == 1) {
        return 'assets/images/svg/check.svg';
      }

      return '';
    }

    assetPath = resolveAssetPath();

    if (assetPath == null) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: Transform.translate(
        key: ValueKey<String>('$assetPath-$svgColor'),
        offset: Offset(4, -4),
        child: SvgPicture.asset(
          assetPath,
          colorFilter:
              svgColor == null
                  ? null
                  : ColorFilter.mode(svgColor!, BlendMode.modulate),
        ),
      ),
    );
  }
}
