import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/dialogs/schedules/weekly_schedule_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/monthly_schedule_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/custom_schedule_dialog.dart';
import 'package:tinycolor2/tinycolor2.dart';

enum ScheduleType { daily, weekly, monthly, custom }

extension ScheduleOptionTypeAction on ScheduleType {
  void handlePrimaryButtonPressed(BuildContext context, ColorProvider cp) {
    switch (this) {
      case ScheduleType.daily:
        Navigator.pop(context);
        break;
      case ScheduleType.weekly:
        _showScheduleDialog(
          context,
          cp,
          builder: (context) => WeeklyScheduleDialog(),
        );
        break;
      case ScheduleType.monthly:
        _showScheduleDialog(
          context,
          cp,
          builder: (context) => MonthlyScheduleDialog(),
        );
        break;
      case ScheduleType.custom:
        _showScheduleDialog(
          context,
          cp,
          builder: (context) => CustomScheduleDialog(),
        );
        break;
    }
  }

  void _showScheduleDialog(
    BuildContext context,
    ColorProvider cp, {
    required WidgetBuilder builder,
  }) {
    Navigator.pop(context); // closes the set schedule dialog
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      barrierColor: cp.greyText.darken().withOpacity(0.3),
      isScrollControlled: true,
      context: context,
      builder: builder,
    );
  }
}
