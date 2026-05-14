import 'package:flutter/material.dart';

import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/habit_details/select_habit_type_widget.dart';

class EnterAmountDurationText extends StatelessWidget {
  const EnterAmountDurationText({
    super.key,
    required this.tp,
    required this.type,
  });

  final ThemeProvider tp;
  final OldHabitType type;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final text =
        "${type == OldHabitType.duration ? loc.enterYourDuration : loc.enterYourAmount}:"
            .toUpperCase();

    return Text.rich(
      TextSpan(
        children:
            text.split(' ').map((word) {
              final isLast = text.split(' ').last == word;
              return TextSpan(
                text: isLast ? word : "$word\n",
                style: TextStyle(
                  letterSpacing: 2,
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  height: 1.2,
                  color: tp.primaryColor,
                ),
              );
            }).toList(),
      ),
    );
  }
}
