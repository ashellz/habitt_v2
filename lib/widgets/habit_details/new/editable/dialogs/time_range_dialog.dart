import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_details/new/editable/schedule_time_field.dart';
import 'package:provider/provider.dart';

enum TimeRangeAction { done, back, editStart, editEnd }

/// "Set time range": tapping a time pops an edit action so the flow can open
/// that time's picker in place of this dialog. Done needs two different times.
class TimeRangeDialog extends StatelessWidget {
  const TimeRangeDialog({super.key, required this.start, required this.end});

  final int start;
  final int end;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.setTimeRange,
      primaryButtonLabel: loc.done,
      primaryButtonEnabled: start != end,
      secondaryButtonLabel: loc.back,
      onSecondaryButtonPressed:
          () => Navigator.of(context).pop(TimeRangeAction.back),
      onPrimaryButtonPressed:
          () => Navigator.of(context).pop(TimeRangeAction.done),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: _timeColumn(
                  context,
                  label: loc.startTimeLabel,
                  minutes: start,
                  action: TimeRangeAction.editStart,
                ),
              ),
              Expanded(
                child: _timeColumn(
                  context,
                  label: loc.endTimeLabel,
                  minutes: end,
                  action: TimeRangeAction.editEnd,
                ),
              ),
            ],
          ),
          // explains why Done is disabled
          if (start == end)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                loc.timeRangeSameTimes,
                style: TextStyle(
                  color: context.watch<ColorProvider>().error,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeColumn(
    BuildContext context, {
    required String label,
    required int minutes,
    required TimeRangeAction action,
  }) {
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
        ScheduleTimeField(
          minutes: minutes,
          expand: true,
          onTap: () => Navigator.of(context).pop(action),
        ),
      ],
    );
  }
}
