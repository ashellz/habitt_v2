import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
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
    this.showCloseButton = false,
    this.onClose,
    this.overrideDefaultButtons = false,
    this.tip,
    this.titleIcon,
    this.titleIconSvgPath,
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

  final bool showCloseButton;
  final VoidCallback? onClose;
  final bool overrideDefaultButtons;
  final String? tip;

  final Widget? titleIcon;
  final String? titleIconSvgPath;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final loc = AppLocalizations.of(context)!;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + keyboardInset,
      ),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cp.isDark ? cp.habitBg : cp.bg,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20),
          // Horizontal paddings are separated because the tip divider needs to reach both ends
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              if (titleIcon != null || titleIconSvgPath != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(10),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cp.isDark ? cp.field : cp.bg,
                    shape: BoxShape.circle,
                  ),
                  child: titleIcon ?? SvgPicture.asset(titleIconSvgPath!),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
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
                              style: TextStyle(
                                color: cp.greyText,
                                fontSize: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showCloseButton)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: NewCircleButton(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(11),
                          svgPath: 'assets/images/new-svg/close.svg',
                          cnIcon: const CNSymbol('xmark', size: 14),
                          onPressed: () {
                            if (onClose != null) {
                              onClose!();
                            } else if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (child != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: child!,
                ),
              if (!overrideDefaultButtons)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
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
                ),
              if (tip != null)
                Column(
                  children: [
                    Divider(color: cp.border, height: 0),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        spacing: 8,
                        children: [
                          SvgPicture.asset(
                            "assets/images/new-svg/tip.svg",
                            colorFilter: ColorFilter.mode(
                              cp.isDark ? cp.lightGreyText : cp.greyText,
                              BlendMode.srcIn,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              tip!,
                              style: TextStyle(
                                color:
                                    cp.isDark ? cp.lightGreyText : cp.greyText,
                              ),
                            ),
                          ),
                        ],
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
