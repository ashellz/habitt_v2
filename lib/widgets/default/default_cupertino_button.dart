import 'package:flutter/cupertino.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class DefaultCupertinoButton extends StatelessWidget {
  const DefaultCupertinoButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.color,
    this.textColor,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final String text;
  final Color? color;
  final Color? textColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.5,
      child: CupertinoButton(
        color: color ?? tp.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        borderRadius: BorderRadius.circular(24),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor ?? tp.primaryTextColor,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
