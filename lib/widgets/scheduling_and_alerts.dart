import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/other_pages/select_habit_time_page.dart';
import 'package:habitt/providers/color_provider.dart';

class SchedulingAndAlerts extends StatelessWidget {
  const SchedulingAndAlerts({super.key, required this.colorProvider});

  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => SelectHabitTimePage()),
          ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: colorProvider.colorScheme.strokeColor,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                "Scheduling and Alerts",
                style: TextStyle(
                  color: colorProvider.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Arrow right
            RotatedBox(
              quarterTurns: 2,
              child: SvgPicture.asset(
                "assets/images/svg/arrow-back.svg",
                height: 32,
                colorFilter: ColorFilter.mode(
                  colorProvider.textColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
