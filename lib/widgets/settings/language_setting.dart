import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/language_option.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/sheets/app_language_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class LanguageSetting extends StatelessWidget {
  const LanguageSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final lp = context.watch<LanguageProvider>();
    final currentLanguage = lp.currentLanguage;
    final lc = currentLanguage?.languageCode.toUpperCase() ?? 'EN';
    final flagPath = currentLanguage?.svgPath ?? LanguageOption.english.svgPath;

    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;

    final loc = AppLocalizations.of(context)!;

    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.language,
          style: TextStyle(
            color: cp.lightGreyText,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        AnimatedContainer(
          duration: Duration(milliseconds: isAndroid ? 0 : 200),
          width: double.infinity,
          padding: const EdgeInsets.only(top: 4, left: 12, right: 4, bottom: 4),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: cp.isDark ? cp.habitBg : cp.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.chooseAppLanguage,
                style: TextStyle(
                  color: cp.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              NewDefaultButton(
                width: 89,
                height: 46,
                color: cp.field,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  spacing: 16,
                  children: [
                    Text(
                      lc,
                      style: TextStyle(
                        color: cp.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (flagPath != null)
                      SvgPicture.asset(flagPath, width: 20, height: 20)
                    else
                      Icon(Icons.language_rounded, size: 20, color: cp.text),
                  ],
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
                    barrierColor: cp.greyText.darken().withOpacity(0.3),
                    isScrollControlled: true,
                    builder: (context) {
                      return AppLanguageSheet(
                        maxSheetHeight: maxSheetHeight,
                        cp: cp,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
