import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class FloatingBottomButton extends StatelessWidget {
  const FloatingBottomButton({
    super.key,
    required this.showButton,
    required this.onPressed,
    required this.label,
    this.enabled = true,
  });

  final bool showButton;
  final Function onPressed;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: SizedBox(
            height: 50,
            width: MediaQuery.of(context).size.width - 32,
            child: ElevatedButton(
              onPressed: () => enabled ? onPressed() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorProvider.colorScheme.darkerStandardColor,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              child: Text(label, style: TextStyle(color: Color(0xFFF8F9FA))),
            ),
          ),
        ),
      ),
    );
  }
}
