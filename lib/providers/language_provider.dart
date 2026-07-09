import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/language_option.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider(this._prefs, [Locale? initialLocale])
    : _locale = initialLocale;

  static const String _localeCodeKey = 'app_locale_code';

  final SharedPreferences _prefs;
  Locale? _locale; // null if not set or not supported
  LanguageOption? get currentLanguage =>
      _locale == null
          ? null
          : LanguageOption.fromLanguageCode(_locale!.languageCode);

  Locale? get locale => _locale;

  // used before the provider is inited, to get the initial locale from shared preferences
  static LanguageProvider fromPrefs(SharedPreferences prefs) {
    debugPrint('[LanguageProvider] Loading locale from prefs');
    final localeCode = prefs.getString(_localeCodeKey);
    debugPrint('[LanguageProvider] locale code: $localeCode');

    final locale = _supportedLocaleFromCode(localeCode);
    debugPrint('[LanguageProvider] locale: $locale');
    // locale is currently gonna be null if localeCode is not supported
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
    // if localecode is null or empty it will use system locale
    // if none of them match suopported locales, it will default to english

    if (localeCode == null || localeCode.isEmpty) {
      localeCode = PlatformDispatcher.instance.locale.languageCode;
    }

    for (final locale in AppLocalizations.supportedLocales) {
      debugPrint(
        'Checking supported locale: ${locale.languageCode} against $localeCode',
      );
      if (locale.languageCode == localeCode) {
        return locale;
      }
    }

    return Locale('en');
  }
}
