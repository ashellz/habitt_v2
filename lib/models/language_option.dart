enum LanguageOption {
  english('en', 'English', 'assets/images/new-svg/languages/en.svg'),
  bosnian('bs', 'Bosanski', 'assets/images/new-svg/languages/ba.svg'),
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
