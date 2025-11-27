import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class MoreOptionsText extends StatelessWidget {
  const MoreOptionsText({super.key, required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          SvgPicture.asset(
            width: 24,
            "assets/images/svg/slider.svg",
            colorFilter: ColorFilter.mode(tp.primaryTextColor, BlendMode.srcIn),
          ),
          Padding(
            padding: EdgeInsets.only(left: 12),
            child: RichText(
              text: TextSpan(
                text: localizations.moreOptions,
                style: TextStyle(color: tp.primaryTextColor),
                children: [
                  TextSpan(
                    text: " (not required)",
                    style: TextStyle(color: tp.mutedTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
