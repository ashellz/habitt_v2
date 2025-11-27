import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/theme_provider.dart';

class NavBackButton extends StatelessWidget {
  const NavBackButton({super.key, required this.tp, this.onPressed});

  final ThemeProvider tp;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.pop(context),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            "assets/images/svg/arrow-back.svg",
            height: 40,
            colorFilter: ColorFilter.mode(tp.primaryTextColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
