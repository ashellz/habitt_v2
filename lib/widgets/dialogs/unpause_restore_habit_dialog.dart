import 'package:flutter/widgets.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:habitt/widgets/habit_details/habit_primary_action_button.dart';
import 'package:provider/provider.dart';

class UnpauseRestoreHabitDialog extends StatelessWidget {
  const UnpauseRestoreHabitDialog({
    super.key,
    required this.title,
    required this.desc,
    required this.buttonText,
    required this.loc,
    required this.isPaused,
    required this.widget,
  });

  final String title;
  final String desc;
  final String buttonText;
  final AppLocalizations loc;
  final bool isPaused;
  final HabitPrimaryActionButton widget;

  @override
  Widget build(BuildContext context) {
    return NewDefaultDialog(
      title: title,
      desc: desc,
      primaryButtonLabel: buttonText,
      secondaryButtonLabel: loc.cancel,
      onPrimaryButtonPressed: () {
        Navigator.of(context).pop();
        isPaused
            ? context.read<HabitProvider>().unpauseHabit(widget.habit)
            : context.read<HabitProvider>().restoreHabit(widget.habit);
      },
      onSecondaryButtonPressed: () {
        Navigator.of(context).pop();
      },
    );
  }
}
