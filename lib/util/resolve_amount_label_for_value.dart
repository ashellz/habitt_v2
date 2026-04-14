import 'package:habitt/util/amount_label_preset.dart';

String resolveAmountLabelForValue(String label, int value) {
  return AmountLabelPreset.resolveForValue(label, value);
}
