import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:provider/provider.dart';

class DefaultDialog extends StatelessWidget {
  const DefaultDialog({
    super.key,
    this.title,
    this.desc,
    this.content,
    this.danger = false,
    this.leftButtonText,
    this.leftButtonCallback,
    this.rightButtonText,
    this.rightButtonCallback,
    this.leftButtonOutlined = true,
    this.rightButtonOutlined = false,
    this.rightButtonEnabled = true,
  });

  final String? title;
  final String? desc;
  final Widget? content;
  final bool danger;
  final String? leftButtonText;
  final String? rightButtonText;
  final VoidCallback? leftButtonCallback;
  final VoidCallback? rightButtonCallback;
  final bool leftButtonOutlined;
  final bool rightButtonOutlined;
  final bool rightButtonEnabled;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    Color dialogColor = tp.surfaceColor;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogColor,
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tp.primaryTextColor,
                      ),
                    ),
                  ),
                ),
              if (desc != null)
                Text(
                  desc!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tp.secondaryTextColor, fontSize: 12),
                ),
              if (content != null) content!,

              Padding(
                padding:
                    rightButtonText != null || leftButtonText == null
                        ? const EdgeInsets.only(top: 8.0)
                        : EdgeInsets.zero,
                child: Row(
                  spacing: 8,
                  children: [
                    if (leftButtonText != null)
                      Expanded(
                        child: DefaultButton(
                          danger: danger,
                          outlined: leftButtonOutlined,
                          onPressed:
                              leftButtonCallback ??
                              () => Navigator.pop(context),
                          label: leftButtonText!,
                        ),
                      ),

                    if (rightButtonText != null)
                      Expanded(
                        child: DefaultButton(
                          enabled: rightButtonEnabled,
                          danger: danger,
                          outlined: rightButtonOutlined,
                          onPressed:
                              rightButtonCallback ??
                              () => Navigator.pop(context),
                          label: rightButtonText!,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
