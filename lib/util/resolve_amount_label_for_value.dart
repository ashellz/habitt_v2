import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/amount_label_preset.dart';

String resolveAmountLabelForValue(
  String label,
  int value,
  AppLocalizations loc, {
  Map<String, String>? customSingulars,
}) {
  final preset = AmountLabelPreset.fromLocalizedLabel(label, loc);
  if (preset != null) {
    return value == 1 ? preset.localizedSingular(loc) : preset.localizedPlural(loc);
  }

  if (customSingulars != null && customSingulars.containsKey(label)) {
    return value == 1 ? customSingulars[label]! : label;
  }

  return label;
}
