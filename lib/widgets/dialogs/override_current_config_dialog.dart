import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: l10n.overrideCurrentConfigTitle,
      desc: l10n.overrideCurrentConfigDesc,
      primaryButtonLabel: l10n.overrideCurrentConfigOverride,
      primaryButtonColor: cp.error,
      secondaryButtonLabel: l10n.overrideCurrentConfigKeepCurrent,
      onPrimaryButtonPressed: () {
        sp.applyPremadeHabitTemplate(
          template,
          localizedName: template.localizedName(l10n),
        );
        Navigator.of(dialogContext).pop();
      },
      onSecondaryButtonPressed: () {
        sp.applyPremadeHabitTemplate(template, overrideConfig: false);
        Navigator.of(dialogContext).pop();
      },
    );
  }
}
