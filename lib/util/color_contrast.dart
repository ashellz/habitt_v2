import 'package:flutter/material.dart';

/// Returns either [light] or [dark] text color depending on which gives better
/// WCAG contrast against the provided [background]. Default candidates are
/// pure white and near-black, but you can override.
///
/// Contrast ratio formula: (L1 + 0.05) / (L2 + 0.05), where L are relative
/// luminance values in linear space. We compute both ratios and choose the
/// higher one to maximize readability.
Color bestContrastingOn(
  Color background, {
  Color light = Colors.white,
  Color dark = const Color(0xFF111111),
}) {
  double lumBg = background.computeLuminance();
  double lumLight = light.computeLuminance();
  double lumDark = dark.computeLuminance();

  double contrastWith(Color fgLumColor, double fgLum) {
    final L1 = lumBg > fgLum ? lumBg : fgLum;
    final L2 = lumBg > fgLum ? fgLum : lumBg;
    return (L1 + 0.05) / (L2 + 0.05);
  }

  final ratioLight = contrastWith(light, lumLight);
  final ratioDark = contrastWith(dark, lumDark);
  return ratioDark >= ratioLight ? dark : light;
}

/// Convenience wrapper using Theme brightness: if background is high luminance
/// prefer dark text; if low luminance prefer light text. This is simpler but
/// less precise than [bestContrastingOn]. Threshold tuned around 0.53.
Color simpleOn(
  Color background, {
  Color light = Colors.white,
  Color dark = const Color(0xFF111111),
}) {
  return background.computeLuminance() > 0.53 ? dark : light;
}
