import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class DefaultButton extends StatelessWidget {
  const DefaultButton({
    super.key,

    required this.onPressed,
    required this.label,
    this.enabled = true,
    this.outlined = false,
    this.danger = false,
  });

  final Function onPressed;
  final String label;
  final bool enabled;
  final bool outlined;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    Color buttonColor =
        danger
            ? colorProvider.red
            : colorProvider.colorScheme.darkerStandardColor;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: IgnorePointer(
            ignoring: !enabled,
            child: SizedBox(
              height: 50,
              width: MediaQuery.of(context).size.width - 32,
              child:
                  outlined
                      ? OutlinedButton(
                        onPressed: () => enabled ? onPressed() : null,
                        style: OutlinedButton.styleFrom(
                          enableFeedback: false,
                          side: BorderSide(color: buttonColor),

                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(color: colorProvider.textColor),
                        ),
                      )
                      : ElevatedButton(
                        onPressed: () => enabled ? onPressed() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
