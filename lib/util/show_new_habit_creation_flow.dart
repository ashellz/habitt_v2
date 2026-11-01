import 'package:flutter/material.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/dialogs/premade_health_sync_dialog.dart';
import 'package:habitt/widgets/sheets/habit_sheet.dart';
import 'package:habitt/widgets/sheets/premade_habits_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

Future<void> showNewHabitCreationFlow(BuildContext context) async {
  final sp = context.read<StateProvider>();
  sp.reset();

  PremadeHabitTemplate? initialTemplate;

  while (context.mounted) {
    final premadeResult = await _showPremadeSheet(context);
    if (!context.mounted || premadeResult == null) {
      return;
    }

    if (premadeResult.action == PremadeHabitSheetAction.skip) {
      initialTemplate = null;
    } else if (premadeResult.action == PremadeHabitSheetAction.select) {
      initialTemplate = premadeResult.template;
    } else {
      continue;
    }

    // before the sheet opens and before any OS prompt
    var healthSync = true;
    if (initialTemplate != null) {
      healthSync = await askPremadeHealthSync(context, initialTemplate);
      if (!context.mounted) {
        return;
      }
    }

    final habitResult = await _showHabitSheet(
      context,
      initialPremadeTemplate: initialTemplate,
      initialPremadeHealthSync: healthSync,
    );

    if (!context.mounted) {
      return;
    }

    if (habitResult == HabitSheetCloseResult.saved) {
      return;
    }

    if (habitResult == HabitSheetCloseResult.reopenPremade) {
      return;
    }

    return;
  }
}

Future<PremadeHabitSheetResult?> _showPremadeSheet(BuildContext context) {
  final cp = context.read<ColorProvider>();

  return showModalBottomSheet<PremadeHabitSheetResult>(
    context: context,
    backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
    barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
    isScrollControlled: true,
    builder: (_) => PremadeHabitsSheet(mode: PremadeHabitSheetMode.create),
  );
}

Future<HabitSheetCloseResult?> _showHabitSheet(
  BuildContext context, {
  PremadeHabitTemplate? initialPremadeTemplate,
  bool initialPremadeHealthSync = true,
}) {
  final cp = context.read<ColorProvider>();

  return showModalBottomSheet<HabitSheetCloseResult>(
    context: context,
    backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
    barrierColor: cp.greyText.darken().withValues(alpha: 0.3),
    isScrollControlled: true,
    builder:
        (_) => HabitSheet(
          initialPremadeTemplate: initialPremadeTemplate,
          initialPremadeHealthSync: initialPremadeHealthSync,
          reopenPremadeOnTopBack: true,
        ),
  );
}
