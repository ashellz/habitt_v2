import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class MoreOptionsText extends StatelessWidget {
  const MoreOptionsText({super.key, required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          SvgPicture.asset(
            "assets/images/svg/slider.svg",
            colorFilter: ColorFilter.mode(
              colorProvider.textColor,
              BlendMode.srcIn,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              localizations.moreOptions,
              style: TextStyle(color: colorProvider.textColor),
            ),
          ),
        ],
      ),
    );
  }
}
