import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:provider/provider.dart';

class SettingsTopSection extends StatelessWidget {
  const SettingsTopSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          loc.settings,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        NewCircleButton(
          svgPath: "assets/images/new-svg/close.svg",
          cnIcon: CNSymbol("xmark", size: 14),

          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            ;
          },
        ),
      ],
    );
  }
}
