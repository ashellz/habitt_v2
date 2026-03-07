import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/util/color_contrast.dart';
import 'package:provider/provider.dart';

enum _ButtonVariant { custom, primary, secondary }

class NewDefaultButton extends StatelessWidget {
  const NewDefaultButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.enabled = true,
    this.color,
    this.textColor,
    this.isLoading = false,
    this.prefix,
    this.height = 52,
  }) : _variant = _ButtonVariant.custom;

  const NewDefaultButton.primary({
    super.key,
    required this.onPressed,
    required this.label,
    this.enabled = true,

    this.isLoading = false,
    this.prefix,
    this.height = 52,
  }) : color = null,
       textColor = Colors.white,
       _variant = _ButtonVariant.primary;

  const NewDefaultButton.secondary({
    super.key,
    required this.onPressed,
    required this.label,
    this.enabled = true,
    this.isLoading = false,
    this.prefix,
    this.height = 52,
  }) : color = null,
       textColor = null,
       _variant = _ButtonVariant.secondary;

  final Function onPressed;
  final String label;
  final bool enabled;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final Widget? prefix;
  final _ButtonVariant _variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    Color buttonColor;
    switch (_variant) {
      case _ButtonVariant.primary:
        buttonColor = cp.main;
        break;
      case _ButtonVariant.secondary:
        buttonColor = cp.secondaryButton;
        break;
      case _ButtonVariant.custom:
        buttonColor = color ?? cp.main;
        break;
    }

    final Color resolvedTextColor = textColor ?? bestContrastingOn(buttonColor);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.5,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        width: double.infinity,
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !enabled,
          child: ElevatedButton(
            onPressed: () => enabled && !isLoading ? onPressed() : null,
            style: ButtonStyle(
              splashFactory: isAndroid ? null : NoSplash.splashFactory,
              elevation: const WidgetStatePropertyAll(0),
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (!states.contains(WidgetState.pressed)) {
                  return null;
                }

                if (isAndroid) {
                  return Colors.white;
                }

                return Colors.white.withValues(alpha: 0.2);
              }),
              backgroundColor: WidgetStatePropertyAll(buttonColor),
              shadowColor: const WidgetStatePropertyAll(Colors.transparent),
              shape: const WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
              ),
            ),
            child:
                isLoading
                    ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          resolvedTextColor,
                        ),
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (prefix != null) ...[
                          prefix!,
                          const SizedBox(width: 10),
                        ],
                        Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            color: resolvedTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
