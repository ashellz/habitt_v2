import 'package:habitt/l10n/app_localizations.dart';

enum AmountLabelPreset {
  steps(singular: 'step', plural: 'steps'),
  glasses(singular: 'glass', plural: 'glasses'),
  pages(singular: 'page', plural: 'pages'),
  dl(singular: 'dl', plural: 'dl'),
  km(singular: 'km', plural: 'km'),
  meals(singular: 'meal', plural: 'meals'),
  times(singular: 'time', plural: 'times');

  static const String defaultAmountLabel = 'times';

  const AmountLabelPreset({required this.singular, required this.plural});

  final String singular;
  final String plural;

  static const List<AmountLabelPreset> _orderedValues = values;

  static List<String> get defaultLabels =>
      _orderedValues.map((preset) => preset.plural).toList(growable: false);

  static AmountLabelPreset? fromLabel(String value) {
    final normalized = value.trim().toLowerCase();
    for (final preset in _orderedValues) {
      if (normalized == preset.singular || normalized == preset.plural) {
        return preset;
      }
    }
    return null;
  }

  static bool isPredefinedLabel(String value) => fromLabel(value) != null;

  static String canonicalize(String value) {
    final preset = fromLabel(value);
    return preset?.plural ?? value.trim().toLowerCase();
  }

  static String resolveForValue(String value, int amount) {
    final preset = fromLabel(value);
    if (preset == null) {
      return value;
    }

    return amount == 1 ? preset.singular : preset.plural;
  }

  // LOCALIZATION

  String localizedSingular(AppLocalizations l) {
    switch (this) {
      case AmountLabelPreset.steps:
        return l.step;
      case AmountLabelPreset.glasses:
        return l.glass;
      case AmountLabelPreset.pages:
        return l.page;
      case AmountLabelPreset.dl:
        return l.dl;
      case AmountLabelPreset.km:
        return l.km;
      case AmountLabelPreset.meals:
        return l.meal;
      case AmountLabelPreset.times:
        return l.time;
    }
  }

  String localizedPlural(AppLocalizations l) {
    switch (this) {
      case AmountLabelPreset.steps:
        return l.steps;
      case AmountLabelPreset.glasses:
        return l.glasses;
      case AmountLabelPreset.pages:
        return l.pages;
      case AmountLabelPreset.dl:
        return l.dl;
      case AmountLabelPreset.km:
        return l.km;
      case AmountLabelPreset.meals:
        return l.meals;
      case AmountLabelPreset.times:
        return l.times;
    }
  }

  static AmountLabelPreset? fromLocalizedLabel(
    String value,
    AppLocalizations l,
  ) {
    final normalized = value.trim().toLowerCase();
    for (final preset in AmountLabelPreset._orderedValues) {
      final singular = preset.localizedSingular(l).trim().toLowerCase();
      final plural = preset.localizedPlural(l).trim().toLowerCase();
      if (normalized == singular || normalized == plural) {
        return preset;
      }
      if (normalized == preset.singular || normalized == preset.plural) {
        return preset;
      }
    }
    return null;
  }

  static bool isPredefinedLabelLocalized(String value, AppLocalizations l) =>
      fromLocalizedLabel(value, l) != null;

  static String canonicalizeLocalized(String value, AppLocalizations l) {
    final preset = fromLocalizedLabel(value, l);
    return preset?.localizedPlural(l) ?? value.trim().toLowerCase();
  }

  static String resolveForValueLocalized(
    String value,
    int amount,
    AppLocalizations l,
  ) {
    final preset = fromLocalizedLabel(value, l);
    if (preset == null) return value;
    return amount == 1
        ? preset.localizedSingular(l)
        : preset.localizedPlural(l);
  }
}
