import 'package:flutter/material.dart';

String colorToHex(Color color, {bool leadingHashSign = true}) {
  final hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
  return leadingHashSign ? '#$hex' : hex;
}

Color hexToColor(String hexString) {
  final cleaned = hexString.replaceAll('#', '').toUpperCase();
  final value = int.parse(cleaned, radix: 16);
  return Color(value);
}
