import 'package:habitt/models/category.dart';
import 'package:habitt/l10n/app_localizations.dart';

String getLocalizedCategoryName(
  Category category,
  AppLocalizations locaizations,
) {
  switch (category.name) {
    case "Any time":
      return locaizations.anyTime;
    case "Morning":
      return locaizations.morning;
    case "Afternoon":
      return locaizations.afternoon;
    case "Evening":
      return locaizations.evening;
    default:
      return category.name;
  }
}
