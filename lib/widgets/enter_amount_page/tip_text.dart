import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/select_habit_type_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TipText extends StatelessWidget {
  const TipText({
    super.key,
    required this.width,
    required this.localizations,
    required this.colorProvider,
    required this.type,
  });

  final double width;
  final AppLocalizations localizations;
  final ColorProvider colorProvider;
  final HabitType type;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width / 2,
      child: Text(
        "${localizations.youCanPressNumberAbove(type == HabitType.amount ? localizations.amount.toLowerCase() : localizations.duration.toLowerCase())} ${type == HabitType.amount ? localizations.orToChangeLabel : ""}",
        style: TextStyle(color: colorProvider.textColor),
      ),
    );
  }
}
