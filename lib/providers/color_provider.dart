import 'package:flutter/material.dart';
import 'package:habitt/models/custom_color_scheme.dart';

class ColorProvider extends ChangeNotifier {
  CustomColorScheme colorScheme = CustomColorScheme(
    disabledColor: Color(0xFFE6F0FF),
    standardColor: Color(0xFFCBE0FF),
    vividColor: Color(0xFF569BFF),
    darkerStandardColor: Color(0xFF457CCC),
  );
}
