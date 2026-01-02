import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class DefaultTextField extends StatefulWidget {
  const DefaultTextField({
    super.key,
    required this.title,
    required this.controller,
    this.maxTextLength = 9999,
    this.maxLines = 1,
    this.topPadding = 24,
    this.digitsOnly = false,
    this.textOnly = false,
    this.obscureText = false,
    this.onTap,
    this.suffix,
  });

  final String title;
  final TextEditingController controller;
  final int maxTextLength;
  final int maxLines;
  final double topPadding;
  final VoidCallback? onTap;
  final bool digitsOnly;
  final bool textOnly;
  final bool obscureText;
  final Widget? suffix;

  @override
  State<DefaultTextField> createState() => _DefaultTextFieldState();
}

class _DefaultTextFieldState extends State<DefaultTextField> {
  bool textObscured = false;

  @override
  void initState() {
    super.initState();
    textObscured = widget.obscureText;
  }

  _toggleObscureText() {
    setState(() {
      textObscured = !textObscured;
    });
  }

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
      padding: EdgeInsets.only(top: widget.topPadding),
      child: TextFormField(
        controller: widget.controller,
        onTap: () => widget.onTap?.call(),
        keyboardAppearance: tp.isDark ? Brightness.dark : Brightness.light,
        inputFormatters: [
          LengthLimitingTextInputFormatter(widget.maxTextLength),
          getFilteringTextInputFormatter(widget.textOnly, widget.digitsOnly) ??
              FilteringTextInputFormatter.deny(""),
        ],
        cursorColor: tp.primaryTextColor,
        cursorWidth: 1.0,
        cursorHeight: 20.0,
        cursorRadius: const Radius.circular(12.0),
        cursorOpacityAnimates: true,
        enableInteractiveSelection: true,
        maxLines: widget.maxLines,
        obscureText: textObscured,

        // Main input text style
        style: TextStyle(color: tp.primaryTextColor, fontSize: 14),

        // Decoration
        decoration: InputDecoration(
          suffixIcon:
              widget.suffix != null
                  ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    child: widget.suffix,
                  )
                  : getSuffixIcon(tp, widget.suffix),
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
          labelText: widget.title,
        ),
      ),
    );
  }

  Widget? getSuffixIcon(ThemeProvider tp, Widget? suffix) {
    if (!widget.obscureText) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: GestureDetector(
        onTap: () => _toggleObscureText(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder:
              (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
          child: SvgPicture.asset(
            key: ValueKey<bool>(textObscured),
            !textObscured
                ? "assets/images/svg/eye.svg"
                : "assets/images/svg/eye-shut.svg",
            excludeFromSemantics: true,
            semanticsLabel: '',
            colorFilter: ColorFilter.mode(
              tp.secondaryTextColor,
              BlendMode.srcIn,
            ),
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
  }
}
