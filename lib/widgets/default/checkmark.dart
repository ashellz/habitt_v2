import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';

class Checkmark extends StatelessWidget {
  const Checkmark({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isDark = cp.isDark;
    final svgPath =
        "assets/images/new-svg/check-${value ? "on" : "off"}-${isDark ? "dark" : "light"}.svg";

    return SvgPicture.asset(svgPath);
  }
}
