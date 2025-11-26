import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class XButton extends StatelessWidget {
  const XButton({super.key, this.onPressed});

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: () {
        if (onPressed != null) {
          onPressed!();
        }
      },
      child: Container(
        height: 20,
        color: Colors.red,
        child: Icon(Icons.close, color: tp.primaryTextColor),
      ),
    );
  }
}
