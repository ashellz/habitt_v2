import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';

class StreakDisplay extends StatelessWidget {
  const StreakDisplay({
    super.key,
    required this.streak,
    required this.completed,
    required this.tp,
    required this.isToday,
  });

  final int streak;
  final bool completed;
  final ThemeProvider tp;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    bool shouldShowStreak() {
      if (streak > 0 && isToday) {
        return true;
      }
      return false;
    }

    String getHabitStreak() {
      // "${completed ? streak + 1 : streak}",
      if (completed && streak > 0) {
        return (streak + 1).toString();
      } else {
        return streak.toString();
      }
    }

    if (!shouldShowStreak()) {
      return SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(right: 5),
      child: SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          children: [
            Image.asset("assets/images/icons/streak.png"),
            Center(
              child: Transform.translate(
                offset: Offset(0, 1.5),
                child: FittedBox(
                  child: Text(
                    getHabitStreak(),

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212529),
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
