import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.title,
    required this.controller,
    this.maxTextLength = 9999,
    this.maxLines = 1,
    this.topPadding = 24,
    this.digitsOnly = false,
    this.textOnly = false,
    this.onTap,
  });

  final String title;
  final TextEditingController controller;
  final int maxTextLength;
  final int maxLines;
  final double topPadding;
  final VoidCallback? onTap;
  final bool digitsOnly;
  final bool textOnly;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    TextInputFormatter? getFilteringTextInputFormatter(
      bool textOnly,
      bool digitsOnly,
    ) {
      if (textOnly) {
        return FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]"));
      } else if (digitsOnly) {
        return FilteringTextInputFormatter.allow(RegExp("[0-9]"));
      } else {
        return null;
      }
    }

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: TextFormField(
        controller: controller,
        onTap: () => onTap?.call(),
        keyboardAppearance: tp.isDark ? Brightness.dark : Brightness.light,
        inputFormatters: [
          LengthLimitingTextInputFormatter(maxTextLength),
          getFilteringTextInputFormatter(textOnly, digitsOnly) ??
              FilteringTextInputFormatter.deny(""),
        ],
        cursorColor: tp.primaryTextColor,
        cursorWidth: 1.0,
        cursorHeight: 20.0,
        cursorRadius: const Radius.circular(12.0),
        cursorOpacityAnimates: true,
        enableInteractiveSelection: true,
        maxLines: maxLines,

        // Main input text style
        style: TextStyle(color: tp.primaryTextColor, fontSize: 14),

        // Decoration
        decoration: InputDecoration(
          alignLabelWithHint: true,

          // Borders
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(24.0)),
            borderSide: BorderSide(color: tp.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.0),
            borderSide: BorderSide(color: tp.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(24.0)),
            borderSide: BorderSide(color: tp.borderColor),
          ),

          // Fill color
          filled: true,
          fillColor: tp.secondaryButtonBackground,

          // Content padding
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),

          //Label (Title)
          labelStyle: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: tp.primaryTextColor,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: title,
        ),
      ),
    );
  }
}
