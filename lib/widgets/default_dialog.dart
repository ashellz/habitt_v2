import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default_button.dart';
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
    this.leftButtonOutlined = false,
    this.rightButtonOutlined = false,
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

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    Color dialogColor = danger ? tp.dangerColor : tp.surfaceColor;

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
              if (title != null && desc != null)
                Center(
                  child: Column(
                    children: [
                      Padding(
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
                      SizedBox(height: 2),
                      Text(
                        desc!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: tp.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              if (content != null) content!,
              if (leftButtonText != null && rightButtonText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
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
                      SizedBox(width: 8),
                      Expanded(
                        child: DefaultButton(
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
