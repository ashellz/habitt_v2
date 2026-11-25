import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/util/get_duration_string.dart';
import 'package:habitt/util/resolve_amount_label_for_value.dart';

/// A goal or progress [value] of [habit] as text: "20m" for a duration
/// (seconds), "8 glasses" for an amount.
String formatGoalValue(
  Habit habit,
  int value,
  AppLocalizations loc, {
  Map<String, String>? customSingulars,
  bool withLabel = true,
}) {
  if (habit.trackingType == HabitTrackingType.duration) {
    return getDurationString(value);
  }
  if (!withLabel) return '$value';
  final label = habit.amountLabel.isEmpty ? loc.times : habit.amountLabel;
  final resolved = resolveAmountLabelForValue(
    label,
    value,
    loc,
    customSingulars: customSingulars,
  );
  return '$value $resolved';
}
