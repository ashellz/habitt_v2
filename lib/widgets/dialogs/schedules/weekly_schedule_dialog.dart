import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';

class WeeklyScheduleDialog extends StatelessWidget {
  const WeeklyScheduleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return NewDefaultDialog(title: "Weekly");
  }
}
