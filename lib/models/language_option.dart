enum LanguageOption {
  english('en', 'English', 'assets/images/new-svg/languages/en.svg'),
  bosnian('bs', 'Bosanski', 'assets/images/new-svg/languages/ba.svg'),
  german('de', 'Deutsch', 'assets/images/new-svg/languages/de.svg'),
  spanish('es', 'Español', 'assets/images/new-svg/languages/es.svg'),
  italian('it', 'Italiano', 'assets/images/new-svg/languages/it.svg'),
  french('fr', 'Français', 'assets/images/new-svg/languages/fr.svg'),
  portugueseBrazil(
    'pt',
    'Português (Brasil)',
    'assets/images/new-svg/languages/br.svg',
  ),
  turkish('tr', 'Türkçe', 'assets/images/new-svg/languages/tr.svg');

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
