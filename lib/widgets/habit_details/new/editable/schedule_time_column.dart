import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_details/new/editable/schedule_time_field.dart';
import 'package:provider/provider.dart';

/// A small [label] above a full width [ScheduleTimeField]. Shared by the time
/// range dialog and the habit sheet's day schedule so the two look the same.
class ScheduleTimeColumn extends StatelessWidget {
  const ScheduleTimeColumn({
    super.key,
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: cp.isDark ? cp.greyText : cp.lightGreyText,
            fontSize: 13,
          ),
        ),
        ScheduleTimeField(minutes: minutes, expand: true, onTap: onTap),
      ],
    );
  }
}
