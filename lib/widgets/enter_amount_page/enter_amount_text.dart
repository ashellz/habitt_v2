import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';

class EnterAmountText extends StatelessWidget {
  const EnterAmountText({super.key, required this.colorProvider});

  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return SizedBox(
      width: MediaQuery.of(context).size.width / 2,
      child: Text(
        "${localizations.enterYourAmount}:".toUpperCase(),
        style: TextStyle(
          fontSize: 38,
          height: 1.2,
          color: colorProvider.colorScheme.darkerStandardColor,
        ),
      ),
    );
  }
}
