import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

class DeleteHabitDialog extends StatelessWidget {
  const DeleteHabitDialog({
    super.key,
    required this.habit,
    required this.dialogContext,
  });

  final Habit habit;
  final BuildContext dialogContext;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return NewDefaultDialog(
      title: "Delete '${habit.resolvedName(context.read<LanguageProvider>().locale?.languageCode)}'?",
      desc: 'Are you sure you want to delete this habit?',
      primaryButtonLabel: 'Delete',
      primaryButtonColor: cp.fail,
      onPrimaryButtonPressed: () {
        Navigator.of(dialogContext).pop(true);
      },
    );
  }
}
