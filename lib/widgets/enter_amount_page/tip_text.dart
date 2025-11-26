import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/habit_details/select_habit_type_widget.dart';
import 'package:habitt/l10n/app_localizations.dart';

class TipText extends StatelessWidget {
  const TipText({
    super.key,
    required this.width,
    required this.localizations,
    required this.tp,
    required this.type,
  });

  final double width;
  final AppLocalizations localizations;
  final ThemeProvider tp;
  final HabitType type;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width / 2,
      child: Text(
        "${localizations.youCanPressNumberAbove(type == HabitType.amount ? localizations.amount.toLowerCase() : localizations.duration.toLowerCase())} ${type == HabitType.amount ? localizations.orToChangeLabel : ""}",
        style: TextStyle(color: tp.primaryTextColor),
      ),
    );
  }
}
