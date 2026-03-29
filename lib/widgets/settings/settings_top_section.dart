import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:provider/provider.dart';

class SettingsTopSection extends StatelessWidget {
  const SettingsTopSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Settings',
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
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
