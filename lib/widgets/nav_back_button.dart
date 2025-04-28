import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';

class NavBackButton extends StatelessWidget {
  const NavBackButton({super.key, required this.colorProvider});

  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            "assets/images/svg/arrow-back.svg",
            height: 40,
            colorFilter: ColorFilter.mode(
              colorProvider.textColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
