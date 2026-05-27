import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/default/default_button.dart';
import 'package:provider/provider.dart';

class OldDefaultDialog extends StatelessWidget {
  const OldDefaultDialog({
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
    this.rightButtonLoading = false,
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
  final bool rightButtonLoading;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    Color dialogColor = tp.surfaceColor;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: dialogColor,
      child: IntrinsicHeight(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: tp.primaryTextColor,
                      ),
                    ),

                  Text(
                    desc!,
                    style: TextStyle(
                      color: tp.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
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
                              () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                          label: leftButtonText!,
                        ),
                      ),

                    if (rightButtonText != null)
                      Expanded(
                        child: DefaultButton(
                          isLoading: rightButtonLoading,
                          enabled: rightButtonEnabled,
                          danger: danger,
                          outlined: rightButtonOutlined,
                          onPressed:
                              rightButtonCallback ??
                              () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
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
