import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';

class CustomScheduleDialog extends StatelessWidget {
  const CustomScheduleDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return NewDefaultDialog(title: "Custom");
  }
}
