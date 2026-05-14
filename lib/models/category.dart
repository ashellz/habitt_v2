import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  /// Returns the localized name for this category based on its id.
  /// This method requires a [BuildContext] to access AppLocalizations.
  String getLocalizedName(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (id) {
      case 1:
        return loc.anyTime;
      case 2:
        return loc.morning;
      case 3:
        return loc.afternoon;
      case 4:
        return loc.evening;
      default:
        return name;
    }
  }
}
