import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';

class NavBackButton extends StatelessWidget {
  const NavBackButton({super.key, required this.tp, this.onPressed});

  final ThemeProvider tp;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30.0),
      child: GestureDetector(
        onTap:
            onPressed ??
            () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tp.elevatedSurfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tp.borderColor, width: 2),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: tp.primaryTextColor,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}
