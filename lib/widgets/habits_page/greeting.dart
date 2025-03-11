import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Greeting extends StatelessWidget {
  const Greeting({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorProvider = context.watch<ColorProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.hello,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        Text(
          "Shellz",
          style: TextStyle(
            fontSize: 38,
            color: colorProvider.colorScheme.darkerStandardColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
