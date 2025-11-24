import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';

class StreakDisplay extends StatelessWidget {
  const StreakDisplay({
    super.key,
    required this.streak,
    required this.completed,
    required this.tp,
  });

  final int streak;
  final bool completed;
  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
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
                    "${completed ? streak + 1 : streak}",
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
