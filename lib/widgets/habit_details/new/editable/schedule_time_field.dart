import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/format_minutes_of_day.dart';
import 'package:provider/provider.dart';

/// Tappable time pill with a clock icon, used for the habit's day schedule.
class ScheduleTimeField extends StatelessWidget {
  const ScheduleTimeField({
    super.key,
    required this.minutes,
    required this.onTap,
    this.expand = false,
  });

  final int minutes;
  final VoidCallback onTap;

  /// Fill the available width with the time and icon at opposite ends.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShapeDecoration(
          color: cp.field,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment:
              expand ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
          spacing: 16,
          children: [
            Text(
              formatMinutesOfDay(context, minutes),
              style: TextStyle(color: cp.text, fontSize: 16),
            ),
            SvgPicture.asset(
              "assets/images/new-svg/clock.svg",
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(cp.lightGreyText, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}
