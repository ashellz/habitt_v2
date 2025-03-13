import 'package:flutter/material.dart';
import 'package:habitt/models/custom_color_scheme.dart';

class ColorProvider extends ChangeNotifier {
  Color textColor = Color(0xFF212529);

  CustomColorScheme colorScheme = CustomColorScheme(
    disabledColor: Color(0xFFF8F9FA),
    standardColor: Color(0xFFEDEDED),
    strokeColor: Color(0xFF97A5B7),
    vividColor: Color(0xFF01377D),
    darkerStandardColor: Color(0xFF01377D),
  );

  final CustomColorScheme _blue = CustomColorScheme(
    disabledColor: Color(0xFFE6F0FF),
    standardColor: Color(0xFFCBE0FF),
    strokeColor: Color(0xFF569BFF),
    vividColor: Color(0xFF569BFF),
    darkerStandardColor: Color(0xFF457CCC),
  );
}
