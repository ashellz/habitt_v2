import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class NewDefaultTextField extends StatefulWidget {
  const NewDefaultTextField({
    super.key,
    this.title,
    required this.controller,
    this.focusNode,
    this.autofocus = false,
    this.titleFontSize = 13,
    this.maxTextLength,
    this.minLines,
    this.maxLines = 1,
    this.topPadding,
    this.digitsOnly = false,
    this.textOnly = false,
    this.obscureText = false,
    this.onTap,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.centerValue = false,
    this.hint,
    this.errorText,
    this.fontWeight = FontWeight.w400,
    this.textStyle,
    this.hintStyle,
    this.regex,
    this.showBorder = false,
    this.color,
    this.enabled = true,
    this.borderRadius = 24.0,
    this.contentPadding = const EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 16,
    ),
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.focusedErrorBorderColor,
    this.counterText,
    this.onSubmitted,
  });

  final String? title;
  final TextEditingController controller;
  final double titleFontSize;
  final FocusNode? focusNode;
  final bool autofocus;
  final int? maxTextLength;
  final int? minLines;
  final int maxLines;
  final double? topPadding;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool digitsOnly;
  final bool textOnly;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final bool centerValue;
  final String? hint;
  final String? errorText;
  final FontWeight fontWeight;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final RegExp? regex;
  final bool showBorder;
  final Color? color;
  final bool enabled;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Color? focusedErrorBorderColor;
  final String? counterText;

  @override
  State<NewDefaultTextField> createState() => _NewDefaultTextFieldState();
}

class _NewDefaultTextFieldState extends State<NewDefaultTextField> {
  bool textObscured = false;

  @override
  void initState() {
    super.initState();
    textObscured = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      textObscured = !textObscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    TextInputFormatter? getFilteringTextInputFormatter(
      bool textOnly,
      bool digitsOnly,
    ) {
      if (widget.regex != null) {
        return FilteringTextInputFormatter.allow(widget.regex!);
      }
      if (textOnly) {
        return FilteringTextInputFormatter.allow(RegExp("[a-zA-Z]"));
      } else if (digitsOnly) {
        return FilteringTextInputFormatter.allow(RegExp("[0-9]"));
      } else {
        return null;
      }
    }

    final filteringFormatter = getFilteringTextInputFormatter(
      widget.textOnly,
      widget.digitsOnly,
    );

    return Padding(
      padding: EdgeInsets.only(top: widget.topPadding ?? 0),
      child: Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            Text(
              widget.title!,
              style: TextStyle(
                color: cp.lightGreyText,
                fontSize: widget.titleFontSize,
                fontWeight: widget.fontWeight,
              ),
            ),

          TextFormField(
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            focusNode: widget.focusNode,
            controller: widget.controller,
            onTap: widget.onTap,
            onFieldSubmitted: widget.onSubmitted,
            onChanged: widget.onChanged,
            textAlign: widget.centerValue ? TextAlign.center : TextAlign.start,
            keyboardAppearance: cp.isDark ? Brightness.dark : Brightness.light,
            inputFormatters: [
              if (widget.maxTextLength != null)
                LengthLimitingTextInputFormatter(widget.maxTextLength),
              if (filteringFormatter != null) filteringFormatter,
            ],
            cursorColor: cp.text,
            cursorWidth: 1.0,
            cursorHeight: 20.0,
            cursorRadius: const Radius.circular(12.0),
            cursorOpacityAnimates: true,
            enableInteractiveSelection: true,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            obscureText: textObscured,

            // Main input text style
            style:
                widget.textStyle ??
                TextStyle(
                  color: cp.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),

            // Decoration
            decoration: InputDecoration(
              errorText: widget.errorText,
              hint:
                  widget.hint != null
                      ? Text(
                        widget.hint!,
                        style:
                            widget.hintStyle ??
                            TextStyle(color: cp.lightGreyText, fontSize: 16),
                      )
                      : null,

              prefixIcon: widget.prefix,
              suffixIcon: widget.suffix ?? getSuffixIcon(cp),
              counterText: widget.counterText,
              alignLabelWithHint: true,

              // Borders
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(widget.borderRadius),
                ),
                borderSide:
                    widget.showBorder
                        ? BorderSide(
                          width: 1,
                          color: widget.borderColor ?? cp.border,
                        )
                        : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                borderSide:
                    widget.showBorder
                        ? BorderSide(
                          width: 1,
                          color: widget.focusedBorderColor ?? cp.border,
                        )
                        : BorderSide.none,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(widget.borderRadius),
                ),
                borderSide:
                    widget.showBorder
                        ? BorderSide(
                          width: 1,
                          color: widget.borderColor ?? cp.border,
                        )
                        : BorderSide.none,
              ),

              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(widget.borderRadius),
                ),
                borderSide:
                    widget.showBorder
                        ? BorderSide(
                          width: 1,
                          color: widget.errorBorderColor ?? cp.error,
                        )
                        : BorderSide.none,
              ),

              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(widget.borderRadius),
                ),
                borderSide:
                    widget.showBorder
                        ? BorderSide(
                          width: 1,
                          color:
                              widget.focusedErrorBorderColor ??
                              widget.errorBorderColor ??
                              cp.error,
                        )
                        : BorderSide.none,
              ),

              // Fill color
              filled: true,
              fillColor: widget.color ?? cp.field,

              // Content padding
              contentPadding: widget.contentPadding,
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
        ],
      ),
    );
  }

  Widget? getSuffixIcon(ColorProvider cp) {
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
                ? "assets/images/new-svg/eye.svg"
                : "assets/images/new-svg/eye-shut.svg",
            excludeFromSemantics: true,
            semanticsLabel: '',
            colorFilter: ColorFilter.mode(cp.lightGreyText, BlendMode.srcIn),
            width: 20,
            height: 20,
          ),
        ),
      ),
    );
  }
}
