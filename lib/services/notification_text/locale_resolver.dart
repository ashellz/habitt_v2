import 'package:flutter/widgets.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HabitNotificationLocaleResolver {
  static const String _localeCodeKey = 'app_locale_code';

  static Future<AppLocalizations> resolveFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeCodeKey);
    return resolveFromLocaleCode(localeCode);
  }

  static AppLocalizations resolveFromLocaleCode(String? localeCode) {
    if (localeCode == null || localeCode.isEmpty) {
      return lookupAppLocalizations(const Locale('en'));
    }

    final supported = AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == localeCode,
    );
    if (!supported) {
      return lookupAppLocalizations(const Locale('en'));
    }

    return lookupAppLocalizations(Locale(localeCode));
  }
}
