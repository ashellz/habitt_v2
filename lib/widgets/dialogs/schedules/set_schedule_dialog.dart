import 'package:flutter/material.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_details/new/schedule_option_widget.dart';
import 'package:provider/provider.dart';

class SetScheduleDialog extends StatelessWidget {
  const SetScheduleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return NewDefaultDialog(
      title: "Set Schedule",
      desc: "How often would you like to do this habit?",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          for (var option in ScheduleType.values)
            ScheduleOptionWidget(scheduleOptionType: option),
        ],
      ),
      onPrimaryButtonPressed: () {
        final sp = context.read<StateProvider>();
        final cp = context.read<ColorProvider>();
        sp.selectedScheduleOption.handlePrimaryButtonPressed(context, cp);
      },
    );
  }
}
