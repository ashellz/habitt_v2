import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/dialogs/schedules/weekly_schedule_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/monthly_schedule_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/custom_schedule_dialog.dart';
import 'package:tinycolor2/tinycolor2.dart';

enum ScheduleOptionType { daily, weekly, monthly, custom }

extension ScheduleOptionTypeAction on ScheduleOptionType {
  void handlePrimaryButtonPressed(BuildContext context, ColorProvider cp) {
    switch (this) {
      case ScheduleOptionType.daily:
        Navigator.pop(context);
        break;
      case ScheduleOptionType.weekly:
        _showScheduleDialog(
          context,
          cp,
          builder: (context) => WeeklyScheduleDialog(),
        );
        break;
      case ScheduleOptionType.monthly:
        _showScheduleDialog(
          context,
          cp,
          builder: (context) => MonthlyScheduleDialog(),
        );
        break;
      case ScheduleOptionType.custom:
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
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      barrierColor: cp.greyText.darken().withOpacity(0.3),
      isScrollControlled: true,
      context: context,
      builder: builder,
    );
  }
}
