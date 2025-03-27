import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class FloatingBottomButton extends StatelessWidget {
  const FloatingBottomButton({
    super.key,
    required this.showButton,
    required this.onPressed,
    required this.label,
  });

  final bool showButton;
  final Function onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, showButton ? -30 : 50, 0),
      child: SizedBox(
        height: 50,
        width: MediaQuery.of(context).size.width - 32,
        child: ElevatedButton(
          onPressed: () => onPressed(),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorProvider.colorScheme.darkerStandardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(color: colorProvider.backgroundColor),
          ),
        ),
      ),
    );
  }
}
