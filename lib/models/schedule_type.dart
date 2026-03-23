import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/show_dialog_sheet.dart';
import 'package:habitt/widgets/dialogs/schedules/schedule_dialog_snapshot.dart';
import 'package:habitt/widgets/dialogs/schedules/weekly_schedule_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/monthly_schedule_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/custom_schedule_dialog.dart';

enum ScheduleType { daily, weekly, monthly, custom }

extension ScheduleOptionTypeAction on ScheduleType {
  void handlePrimaryButtonPressed(
    BuildContext context,
    ColorProvider cp, {
    required ScheduleDialogSnapshot rootSnapshot,
  }) {
    switch (this) {
      case ScheduleType.daily:
        Navigator.pop(context, true);
        break;
      case ScheduleType.weekly:
        _showScheduleDialog(
          context,
          builder:
              (context) => WeeklyScheduleDialog(rootSnapshot: rootSnapshot),
        );
        break;
      case ScheduleType.monthly:
        _showScheduleDialog(
          context,
          builder:
              (context) => MonthlyScheduleDialog(rootSnapshot: rootSnapshot),
        );
        break;
      case ScheduleType.custom:
        _showScheduleDialog(
          context,
          builder:
              (context) => CustomScheduleDialog(rootSnapshot: rootSnapshot),
        );
        break;
    }
  }

  void _showScheduleDialog(
    BuildContext context, {
    required WidgetBuilder builder,
  }) {
    Navigator.pop(context, true); // closes the set schedule dialog
    showDialogSheet(context: context, builder: builder);
  }
}
