import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:habitt/models/habit.dart';

/// Whether the habit editor shows its "Sync from Health" section on this
/// device: a phone whose Health store is available (see HealthWidget).
bool healthEditorShown({required bool healthAvailable}) =>
    !kIsWeb && (Platform.isIOS || Platform.isAndroid) && healthAvailable;

/// Puts [original]'s Health link and the targets it drives back onto
/// [edited] when the editor couldn't show them, so saving a Health habit from
/// a phone without Health (or before its availability check finished) never
/// unlinks it or changes its goal. A habit that isn't linked is left as is.
///
/// Values that come back unchanged get no new field timestamp, so the save
/// can't win a merge against the reading phone either.
void keepHiddenHealthFields(
  Habit edited, {
  required Habit original,
  required bool editorShown,
}) {
  if (editorShown || original.healthMetric == null) return;
  edited.healthMetric = original.healthMetric;
  edited.healthWorkoutFilter = original.healthWorkoutFilter;
  edited.healthBedtimeDayBefore = original.healthBedtimeDayBefore;
  edited.toleranceMinutes = original.toleranceMinutes;
  edited.trackingType = original.trackingType;
  edited.amount = original.amount;
  edited.duration = original.duration;
  edited.amountLabel = original.amountLabel;
}
