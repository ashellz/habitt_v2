import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';

class AdditionalTaskSwitch extends StatelessWidget {
  const AdditionalTaskSwitch({
    super.key,
    required this.colorProvider,
    required this.stateProvider,
  });

  final ColorProvider colorProvider;
  final StateProvider stateProvider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Additional task",
                  style: TextStyle(
                    color: colorProvider.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                activeTrackColor: colorProvider.colorScheme.darkerStandardColor,
                activeColor: Colors.white,
                inactiveThumbColor: colorProvider.textColor,
                inactiveTrackColor: colorProvider.standardColor,
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
                style: TextStyle(color: colorProvider.textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
