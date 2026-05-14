import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/amount_label_preset.dart';

String resolveAmountLabelForValue(
  String label,
  int value,
  AppLocalizations loc,
) {
  return AmountLabelPreset.resolveForValueLocalized(label, value, loc);
}
