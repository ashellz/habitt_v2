import 'package:flutter/material.dart';

/// Formats minutes since midnight as a localized clock time. Bedtimes are
/// stored past 1440 for the small hours, so the value is wrapped first.
String formatMinutesOfDay(BuildContext context, int minutes) {
  final normalized = minutes % (24 * 60);
  return MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60));
}
