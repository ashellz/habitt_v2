import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/models/language_option.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/sheets/app_language_sheet.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    return Scaffold(
      backgroundColor: cp.habitBg,
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 20),
        child: ListView(
          children: [
            SettingsTopSection(cp: cp),
            Padding(
              padding: EdgeInsets.only(top: 26),
              child: Column(spacing: 10, children: [LanguageSetting()]),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguageSetting extends StatelessWidget {
  const LanguageSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final lp = context.watch<LanguageProvider>();
    final currentLanguage = lp.currentLanguage;
    final lc = currentLanguage?.languageCode.toUpperCase() ?? 'en';
    final flagPath = currentLanguage?.svgPath ?? LanguageOption.english.svgPath;

    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height - 59 - 16;

    return Column(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: TextStyle(
            color: cp.lightGreyText,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 4, left: 12, right: 4, bottom: 4),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: cp.bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose app language',
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

class SettingsTopSection extends StatelessWidget {
  const SettingsTopSection({super.key, required this.cp});

  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Settings',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cp.text,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        NewCircleButton(
          svgPath: "assets/images/new-svg/close.svg",
          cnIcon: CNSymbol("xmark", size: 14),

          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
