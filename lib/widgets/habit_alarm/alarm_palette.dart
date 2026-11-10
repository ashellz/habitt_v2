import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Colours of the ringing alarm page, built like the Pixel Clock ringing
/// screen: every colour is a tone of the accent's hue (HCT), so the page reads
/// as the accent instead of black. Always dark, like a clock app at night.
///
/// Chroma/tone values were measured from the Pixel screen (background
/// chroma 7.4 tone 9, secondary button chroma 16.5 tone 25, text tone 91).
class AlarmPalette {
  const AlarmPalette._({
    required this.background,
    required this.text,
    required this.primaryButton,
    required this.onPrimaryButton,
    required this.secondaryButton,
    required this.onSecondaryButton,
  });

  /// [accent] is the theme's dark-mode accent (the primary button colour).
  factory AlarmPalette.fromAccent(Color accent) {
    final hct = Hct.fromInt(accent.toARGB32());
    final hue = hct.hue;
    Color tone(double chroma, double tone) =>
        Color(Hct.from(hue, chroma, tone).toInt());

    return AlarmPalette._(
      background: tone(8, 9),
      text: tone(8, 91),
      primaryButton: accent,
      // dark tone of the accent on the accent, like Pixel's olive on yellow
      onPrimaryButton: tone(hct.chroma.clamp(0, 40).toDouble(), 20),
      secondaryButton: tone(17, 25),
      onSecondaryButton: tone(18, 80),
    );
  }

  final Color background;
  final Color text;
  final Color primaryButton;
  final Color onPrimaryButton;
  final Color secondaryButton;
  final Color onSecondaryButton;
}
