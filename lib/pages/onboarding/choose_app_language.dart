import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/language_option.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_text_field.dart';
import 'package:habitt/widgets/settings/language_option_widget.dart';
import 'package:provider/provider.dart';

class ChooseAppLanguage extends StatefulWidget {
  const ChooseAppLanguage({super.key, this.onNext});

  final VoidCallback? onNext;

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

  Widget _buildLanguageRows({required ColorProvider cp}) {
    final loc = AppLocalizations.of(context)!;
    final query = searchController.text.trim().toLowerCase();
    final items =
        LanguageOption.values.where((option) {
          return query.isEmpty ||
              option.displayName.toLowerCase().contains(query) ||
              option.languageCode.contains(query);
        }).toList();

    if (items.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/images/new-svg/no-languages.svg"),
            Text(
              loc.noLanguagesFound,
              style: TextStyle(
                color: cp.lightGreyText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];

    for (int i = 0; i < items.length; i += 2) {
      final rowItems = items.sublist(i, (i + 2).clamp(0, items.length));
      final rowChildren = <Widget>[];

      for (int j = 0; j < rowItems.length; j++) {
        final item = rowItems[j];

        final labelWidget = Expanded(
          child: LanguageOptionWidget(languageOption: item),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: rows,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        color: cp.bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 35),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loc.chooseAppLanguage,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: cp.text,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, 2),
                            child: IconButton(
                              icon: Icon(
                                cp.isDark ? Icons.dark_mode : Icons.sunny,
                              ),
                              color: cp.text,
                              onPressed: () {
                                cp.setMode(
                                  cp.isDark ? ColorMode.light : ColorMode.dark,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: NewDefaultTextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        hint: loc.findALanguage,
                        suffix: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: SvgPicture.asset(
                            'assets/images/new-svg/search.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              cp.text,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildLanguageRows(cp: cp),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NewDefaultButton.primary(
                    label: loc.next,
                    onPressed: () {
                      widget.onNext?.call();
                    },
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
