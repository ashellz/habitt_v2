import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';

class NewDefaultDialog extends StatelessWidget {
  const NewDefaultDialog({
    super.key,
    this.child,
    required this.title,
    this.primaryButtonLabel,
    this.primaryButtonEnabled = true,
    this.showSecondaryButton = true,
    this.secondaryButtonLabel,
    this.desc,
    this.onPrimaryButtonPressed,
    this.onSecondaryButtonPressed,
    this.primaryButtonColor,
  });

  final Widget? child;
  final String title;
  final String? desc;
  final String? secondaryButtonLabel;
  final String? primaryButtonLabel;
  final bool primaryButtonEnabled;
  final bool showSecondaryButton;
  final VoidCallback? onPrimaryButtonPressed;
  final VoidCallback? onSecondaryButtonPressed;
  final Color? primaryButtonColor;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final loc = AppLocalizations.of(context)!;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 40 + keyboardInset),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cp.isDark ? cp.habitBg : cp.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (desc != null)
                    Text(
                      desc!,
                      style: TextStyle(color: cp.greyText, fontSize: 16),
                    ),
                ],
              ),
              if (child != null) child!,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  if (showSecondaryButton)
                    Expanded(
                      child: NewDefaultButton.secondary(
                        onPressed: () {
                          if (onSecondaryButtonPressed != null) {
                            onSecondaryButtonPressed!();
                          } else {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            ;
                          }
                        },
                        label: secondaryButtonLabel ?? loc.cancel,
                      ),
                    ),
                  Expanded(
                    child: NewDefaultButton.primary(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      enabled: primaryButtonEnabled,
                      color: primaryButtonColor,
                      onPressed: () {
                        if (onPrimaryButtonPressed != null) {
                          onPrimaryButtonPressed!();
                        } else {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          ;
                        }
                      },
                      label: primaryButtonLabel ?? loc.done,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
