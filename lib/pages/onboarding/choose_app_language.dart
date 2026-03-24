import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:provider/provider.dart';

enum LanguageOption {
  english('en', 'English', 'assets/images/new-svg/languages/en.svg'),
  bosnian('bs', 'Bosnian', 'assets/images/new-svg/languages/ba.svg'),
  german('de', 'Deutsch', 'assets/images/new-svg/languages/de.svg'),
  spanish('es', 'Español', 'assets/images/new-svg/languages/es.svg'),
  italian('it', 'Italiano', 'assets/images/new-svg/languages/it.svg');

  final String languageCode;
  final String displayName;
  final String? svgPath;

  const LanguageOption(this.languageCode, this.displayName, this.svgPath);

  static LanguageOption? fromLanguageCode(String languageCode) {
    for (final option in values) {
      if (option.languageCode == languageCode) {
        return option;
      }
    }
    return null;
  }
}

class ChooseAppLanguage extends StatefulWidget {
  const ChooseAppLanguage({super.key});

  @override
  State<ChooseAppLanguage> createState() => _ChooseAppLanguageState();
}

class _ChooseAppLanguageState extends State<ChooseAppLanguage> {
  final TextEditingController searchController = TextEditingController();
  LanguageOption? selectedLanguage;
  bool _selectionInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectionInitialized) {
      return;
    }

    final locale = context.read<LanguageProvider>().locale;
    selectedLanguage = LanguageOption.fromLanguageCode(
      locale?.languageCode ?? Localizations.localeOf(context).languageCode,
    );
    _selectionInitialized = true;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Widget> _buildLanguageRows({required ColorProvider cp}) {
    final checkSvgPath =
        cp.isDark
            ? 'assets/images/new-svg/check-on-dark.svg'
            : 'assets/images/new-svg/check-on-light.svg';

    const selectionDuration = Duration(milliseconds: 200);
    const iconTurns = 0.18;

    final query = searchController.text.trim().toLowerCase();
    final items =
        LanguageOption.values.where((option) {
          return query.isEmpty ||
              option.displayName.toLowerCase().contains(query) ||
              option.languageCode.contains(query);
        }).toList();

    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'No languages found',
            style: TextStyle(
              color: cp.lightGreyText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ];
    }

    final rows = <Widget>[];

    for (int i = 0; i < items.length; i += 2) {
      final rowItems = items.sublist(i, (i + 2).clamp(0, items.length));
      final rowChildren = <Widget>[];

      for (int j = 0; j < rowItems.length; j++) {
        final item = rowItems[j];

        final labelWidget = Expanded(
          child: SizedBox(
            height: 46,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color:
                        selectedLanguage == item
                            ? cp.main.withValues(alpha: 0.2)
                            : cp.border,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                color:
                    selectedLanguage == item
                        ? cp.main.withValues(alpha: 0.1)
                        : Colors.transparent,
              ),
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<LanguageProvider>().setLocale(
                    Locale(item.languageCode),
                  );
                  if (!mounted) {
                    return;
                  }

                  setState(() {
                    selectedLanguage = item;
                  });
                },
                style: ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                  elevation: const WidgetStatePropertyAll(0),
                  overlayColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (!states.contains(WidgetState.pressed)) {
                      return null;
                    }
                    return cp.bg.withValues(alpha: 0.2);
                  }),
                  backgroundColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
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
                        if (item.svgPath != null)
                          SvgPicture.asset(item.svgPath!, width: 20, height: 20)
                        else
                          Icon(
                            Icons.language_rounded,
                            size: 20,
                            color: cp.lightGreyText,
                          ),
                        Text(
                          item.displayName,
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
                        opacity: selectedLanguage == item ? 1 : 0,
                        child: AnimatedScale(
                          duration: selectionDuration,
                          curve: Curves.easeOutBack,
                          scale: selectedLanguage == item ? 1 : 0.7,
                          child: AnimatedRotation(
                            duration: selectionDuration,
                            curve: Curves.easeOutBack,
                            turns: selectedLanguage == item ? 0 : iconTurns,
                            child: SvgPicture.asset(checkSvgPath),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        rowChildren.add(labelWidget);

        if (j < rowItems.length - 1) {
          rowChildren.add(const SizedBox(width: 10));
        }
      }

      if (rowItems.length == 1) {
        rowChildren.add(const SizedBox(width: 10));
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }

      rows.add(Row(children: rowChildren));
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 35),
                  child: Text(
                    'Choose app language',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: cp.text,
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: NewDefaultTextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    hint: 'Find a language',
                    suffix: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: SvgPicture.asset(
                        'assets/images/new-svg/search.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: _buildLanguageRows(cp: cp),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NewDefaultButton(label: 'Next', onPressed: () {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
