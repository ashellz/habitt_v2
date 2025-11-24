import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';

class AdditionalTaskSwitch extends StatelessWidget {
  const AdditionalTaskSwitch({
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
                "Additional task",
                style: TextStyle(
                  color: tp.primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Switch(
              activeTrackColor: tp.primaryColor,
              activeColor: Colors.white,
              inactiveThumbColor: tp.primaryTextColor,
              inactiveTrackColor: tp.secondaryButtonBackground,
              value: stateProvider.isAdditional,
              onChanged: (value) => stateProvider.toggleAditional(),
            ),
          ],
        ),
        Transform.translate(
          offset: Offset(0, -10),
          child: Padding(
            padding: const EdgeInsets.only(right: 55),
            child: Text(
              "If checked, habit won't count for 'All habits completed streak'.",
              style: TextStyle(color: tp.primaryTextColor),
            ),
          ),
        ),
      ],
    );
  }
}
