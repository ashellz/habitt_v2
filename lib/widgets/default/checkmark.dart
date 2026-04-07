import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class Checkmark extends StatelessWidget {
  const Checkmark({
    super.key,
    required this.value,
    this.secondaryCheckmarks = false,
  });

  final bool value;
  final bool secondaryCheckmarks;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isDark = cp.isDark;

    final secondarySvgPath =
        'assets/images/new-svg/check-${value ? 'off' : 'on'}-inverted-${isDark ? 'dark' : 'light'}.svg';
    final svgPath =
        "assets/images/new-svg/check-${value ? "on" : "off"}-${isDark ? "dark" : "light"}.svg";

    return SvgPicture.asset(secondaryCheckmarks ? secondarySvgPath : svgPath);
  }
}
