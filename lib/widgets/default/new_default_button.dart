import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

enum _ButtonVariant { custom, primary, secondary, primarySmall, secondarySmall }

class NewDefaultButton extends StatelessWidget {
  const NewDefaultButton({
    super.key,
    required this.onPressed,
    this.label,
    this.enabled = true,
    this.color,
    this.textColor,
    this.isLoading = false,
    this.prefix,
    this.height = 52,
    this.width,
    this.isGradient = true,
    this.child,
    this.padding,
  }) : _variant = _ButtonVariant.custom;

  const NewDefaultButton.primary({
    super.key,
    required this.onPressed,
    this.label,
    this.enabled = true,

    this.isLoading = false,
    this.prefix,
    this.height = 52,
    this.child,
    this.padding = const EdgeInsets.only(),
    this.textColor,
  }) : color = null,
       width = null,
       isGradient = true,
       _variant = _ButtonVariant.primary;

  const NewDefaultButton.secondary({
    super.key,
    required this.onPressed,
    this.label,
    this.enabled = true,
    this.isLoading = false,
    this.prefix,
    this.height = 52,
    this.child,
    this.padding = const EdgeInsets.only(),
    this.textColor,
    this.width,
  }) : color = null,
       isGradient = false,
       _variant = _ButtonVariant.secondary;

  const NewDefaultButton.primarySmall({
    super.key,
    required this.onPressed,
    required this.label,
    this.enabled = true,
    this.isLoading = false,
    this.prefix,
    this.width = 66,
    this.height = 36,
    this.child,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
  }) : color = null,
       isGradient = true,
       _variant = _ButtonVariant.primarySmall;

  const NewDefaultButton.secondarySmall({
    super.key,
    required this.onPressed,
    required this.label,
    this.enabled = true,
    this.isLoading = false,
    this.prefix,
    this.width = 66,
    this.height = 36,
    this.child,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
  }) : color = null,
       isGradient = false,
       _variant = _ButtonVariant.secondarySmall;

  final Function onPressed;
  final String? label;
  final bool enabled;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final Widget? prefix;
  final _ButtonVariant _variant;
  final double height;
  final double? width;
  final bool isGradient;
  final Widget? child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final Gradient gradient = LinearGradient(
      begin: Alignment(0.09, 0.11),
      end: Alignment(0.86, 0.90),
      colors: [cp.mainButtonLeftGradient, cp.mainButtonRightGradient],
    );

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
      case _ButtonVariant.primarySmall:
        buttonColor = cp.main;
        break;
      case _ButtonVariant.secondarySmall:
        buttonColor = cp.secondaryButton;
        break;
    }

    final bool isMainButtonVariant =
        _variant == _ButtonVariant.primary ||
        _variant == _ButtonVariant.primarySmall;
    final Color resolvedTextColor =
        textColor ?? (isMainButtonVariant ? cp.bg : cp.text);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.5,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        width: width,
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Container(
            decoration: BoxDecoration(
              gradient: isGradient && color == null ? gradient : null,
              color: isGradient && color == null ? null : buttonColor,
              borderRadius: BorderRadius.circular(24),
            ),
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
                    return null;
                  }

                  return cp.bg.withValues(alpha: 0.2);
                }),
                backgroundColor: WidgetStatePropertyAll(
                  isGradient && color == null
                      ? Colors.transparent
                      : buttonColor,
                ),
                shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                shape: const WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                ),
                padding: WidgetStatePropertyAll(
                  padding ?? const EdgeInsets.symmetric(horizontal: 20),
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
                          if (child != null)
                            child!
                          else if (label != null)
                            Text(
                              label!,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                color: resolvedTextColor,
                                fontSize:
                                    _variant == _ButtonVariant.primarySmall ||
                                            _variant ==
                                                _ButtonVariant.secondarySmall
                                        ? 14
                                        : 18,
                                fontWeight: FontWeight.w500,
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
