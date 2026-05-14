import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/default_switch.dart';
import 'package:habitt/l10n/app_localizations.dart';

class OptionalHabitSwitch extends StatelessWidget {
  const OptionalHabitSwitch({
    super.key,
    required this.tp,
    required this.stateProvider,
  });

  final ThemeProvider tp;
  final StateProvider stateProvider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.optionalHabit,
                style: TextStyle(
                  color: tp.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DefaultSwitch(
              onTap: () => stateProvider.toggleOptional(),
              switchValue: stateProvider.isOptional,
            ),
          ],
        ),
        Transform.translate(
          offset: Offset(0, -10),
          child: Padding(
            padding: const EdgeInsets.only(right: 55),
            child: Text(
              AppLocalizations.of(context)!.ifCheckedHabitWontCountForThePerfectDaysStreak,
              style: TextStyle(color: tp.primaryTextColor),
            ),
          ),
        ),
      ],
    );
  }
}
