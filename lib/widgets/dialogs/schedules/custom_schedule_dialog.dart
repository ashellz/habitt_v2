import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/dialogs/schedules/set_schedule_dialog.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class CustomScheduleDialog extends StatelessWidget {
  const CustomScheduleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return NewDefaultDialog(
      title: "Custom",
      onSecondaryButtonPressed: () {
        Navigator.pop(context);
        showModalBottomSheet(
          backgroundColor: Colors.transparent,
          barrierColor: cp.greyText.darken().withOpacity(0.3),
          isScrollControlled: true,
          context: context,
          builder: (context) => SetScheduleDialog(),
        );
      },
      child: Column(),
    );
  }
}
