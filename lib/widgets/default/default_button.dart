import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class DefaultButton extends StatelessWidget {
  const DefaultButton({
    super.key,

    required this.onPressed,
    required this.label,
    this.enabled = true,
    this.outlined = false,
    this.danger = false,
    this.offsetLabel = false,
    this.color,
    this.borderColor,
  });

  final Function onPressed;
  final String label;
  final bool enabled;
  final bool outlined;
  final bool danger;
  final bool offsetLabel;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    Color buttonColor =
        danger ? tp.dangerColor : color ?? tp.primaryButtonBackground;

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
                          style: TextStyle(color: tp.primaryTextColor),
                        ),
                      )
                      : Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => enabled ? onPressed() : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(24),
                                  ),
                                  side: BorderSide(
                                    color: borderColor ?? Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child:
                                  offsetLabel
                                      ? null
                                      : Text(
                                        label,
                                        style: TextStyle(color: Colors.white),
                                      ),
                            ),
                          ),
                          if (offsetLabel)
                            Align(
                              alignment: Alignment.topLeft,
                              child: Transform.translate(
                                offset: const Offset(14, -7.75),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: tp.primaryTextColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
