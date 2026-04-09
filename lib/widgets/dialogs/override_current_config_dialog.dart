import 'package:flutter/material.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class OverrideCurrentConfigDialog extends StatelessWidget {
  const OverrideCurrentConfigDialog({
    super.key,
    required this.dialogContext,
    required this.template,
  });

  final BuildContext dialogContext;
  final PremadeHabitTemplate template;

  @override
  Widget build(BuildContext context) {
    final sp = context.read<StateProvider>();
    final cp = context.watch<ColorProvider>();

    return NewDefaultDialog(
      title: 'Override current configuration?',
      desc:
          'Override current habit details with the template or keep current options?',
      primaryButtonLabel: 'Override',
      primaryButtonColor: cp.error,
      secondaryButtonLabel: 'Keep current',
      onPrimaryButtonPressed: () {
        sp.applyPremadeHabitTemplate(template);
        Navigator.of(dialogContext).pop();
      },
      onSecondaryButtonPressed: () {
        sp.applyPremadeHabitTemplate(template, overrideConfig: false);
        Navigator.of(dialogContext).pop();
      },
    );
  }
}
