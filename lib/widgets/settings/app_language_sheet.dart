import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/models/language_option.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:provider/provider.dart';

class LanguageOptionWidget extends StatelessWidget {
  const LanguageOptionWidget({super.key, required this.languageOption});

  final LanguageOption languageOption;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    final lp = context.read<LanguageProvider>();
    final selectedLanguage = LanguageOption.fromLanguageCode(
      lp.locale?.languageCode ?? Localizations.localeOf(context).languageCode,
    );

    final checkSvgPath =
        cp.isDark
            ? 'assets/images/new-svg/check-on-dark.svg'
            : 'assets/images/new-svg/check-on-light.svg';

    const selectionDuration = Duration(milliseconds: 200);
    const iconTurns = 0.18;

    return SizedBox(
      height: 46,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color:
                  selectedLanguage == languageOption
                      ? cp.main.withValues(alpha: 0.2)
                      : cp.border,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          color:
              selectedLanguage == languageOption
                  ? cp.main.withValues(alpha: 0.1)
                  : Colors.transparent,
        ),
        child: ElevatedButton(
          onPressed: () async {
            await context.read<LanguageProvider>().setLocale(
              Locale(languageOption.languageCode),
            );
          },
          style: ButtonStyle(
            splashFactory: NoSplash.splashFactory,
            elevation: const WidgetStatePropertyAll(0),
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (!states.contains(WidgetState.pressed)) {
                return null;
              }
              return cp.bg.withValues(alpha: 0.2);
            }),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                spacing: 10,
                children: [
                  if (languageOption.svgPath != null)
                    SvgPicture.asset(
                      languageOption.svgPath!,
                      width: 20,
                      height: 20,
                    )
                  else
                    Icon(
                      Icons.language_rounded,
                      size: 20,
                      color: cp.lightGreyText,
                    ),
                  Text(
                    languageOption.displayName,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 20,
                height: 20,
                child: AnimatedOpacity(
                  duration: selectionDuration,
                  curve: Curves.easeOut,
                  opacity: selectedLanguage == languageOption ? 1 : 0,
                  child: AnimatedScale(
                    duration: selectionDuration,
                    curve: Curves.easeOutBack,
                    scale: selectedLanguage == languageOption ? 1 : 0.7,
                    child: AnimatedRotation(
                      duration: selectionDuration,
                      curve: Curves.easeOutBack,
                      turns: selectedLanguage == languageOption ? 0 : iconTurns,
                      child: SvgPicture.asset(checkSvgPath),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
