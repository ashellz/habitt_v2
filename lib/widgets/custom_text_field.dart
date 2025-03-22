import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.title,
    required this.controller,
    this.maxTextLength = 9999,
    this.maxLines = 1,
    this.topPadding = 24,
  });

  final String title;
  final TextEditingController controller;
  final int maxTextLength;
  final int maxLines;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final ColorProvider colorProvider = context.watch<ColorProvider>();

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: TextFormField(
        textInputAction: TextInputAction.done,
        keyboardAppearance:
            Theme.of(context).brightness == Brightness.dark
                ? Brightness.dark
                : Brightness.light,
        inputFormatters: [LengthLimitingTextInputFormatter(maxTextLength)],
        cursorColor: colorProvider.textColor,
        cursorWidth: 1.0,
        cursorHeight: 20.0,
        cursorRadius: const Radius.circular(12.0),
        cursorOpacityAnimates: true,
        enableInteractiveSelection: true,
        maxLines: maxLines,

        // Main input text style
        style: TextStyle(color: colorProvider.textColor, fontSize: 14),

        // Decoration
        decoration: InputDecoration(
          alignLabelWithHint: true,

          // Borders
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(
              color: colorProvider.colorScheme.strokeColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: colorProvider.colorScheme.strokeColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(
              color: colorProvider.colorScheme.strokeColor,
            ),
          ),

          // Fill color
          filled: true,
          fillColor: colorProvider.standardColor,

          // Content padding
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),

          //Label (Title)
          labelStyle: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: colorProvider.textColor,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: title,
        ),
      ),
    );
  }
}
