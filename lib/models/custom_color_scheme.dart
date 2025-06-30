import 'package:flutter/material.dart';

class CustomColorScheme {
  const CustomColorScheme({
    required this.name,
    required this.disabledColor,
    required this.standardColor,
    required this.vividColor,
    required this.darkerStandardColor,
    required this.strokeColor,
  });

  final String name;
  final Color disabledColor;
  final Color standardColor;
  final Color vividColor;
  final Color darkerStandardColor;
  final Color strokeColor;
}
