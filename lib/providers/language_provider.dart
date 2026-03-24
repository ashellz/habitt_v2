import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider(this._prefs, [Locale? initialLocale])
    : _locale = initialLocale;

  static const String _localeCodeKey = 'app_locale_code';

  final SharedPreferences _prefs;
  Locale? _locale;

  Locale? get locale => _locale;

  static LanguageProvider fromPrefs(SharedPreferences prefs) {
    final localeCode = prefs.getString(_localeCodeKey);
    final locale = _supportedLocaleFromCode(localeCode);
    return LanguageProvider(prefs, locale);
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    )) {
      return;
    }

    if (_locale?.languageCode == locale.languageCode) {
      return;
    }

    _locale = Locale(locale.languageCode);
    await _prefs.setString(_localeCodeKey, _locale!.languageCode);
    notifyListeners();
  }

  Future<void> clearLocale() async {
    if (_locale == null) {
      return;
    }

    _locale = null;
    await _prefs.remove(_localeCodeKey);
    notifyListeners();
  }

  static Locale? _supportedLocaleFromCode(String? localeCode) {
    if (localeCode == null || localeCode.isEmpty) {
      return null;
    }

    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == localeCode) {
        return locale;
      }
    }

    return null;
  }
}
