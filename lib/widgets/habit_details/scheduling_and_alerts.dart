import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/other_pages/select_habit_time_page.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/l10n/app_localizations.dart';

class SchedulingAndAlerts extends StatelessWidget {
  const SchedulingAndAlerts({super.key, required this.tp});

  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
            horizontal: BorderSide(color: tp.borderColor),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                loc.schedulingAndAlerts,
                style: TextStyle(
                  color: tp.primaryTextColor,
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
                  tp.primaryTextColor,
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
