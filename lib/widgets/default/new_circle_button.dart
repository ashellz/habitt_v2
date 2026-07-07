import 'package:cupertino_native_better/components/button.dart';
import 'package:cupertino_native_better/style/button_style.dart';
import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/supports_liquid_glass.dart';
import 'package:provider/provider.dart';

class NewCircleButton extends StatefulWidget {
  const NewCircleButton({
    super.key,
    required this.svgPath,
    required this.cnIcon,
    this.width = 46,
    this.height = 46,
    this.color,
    this.textColor,
    this.onPressed,
    this.padding,
    this.native = true,
  });

  final String svgPath;
  final CNSymbol cnIcon;
  final Color? color;
  final Color? textColor;
  final double width;
  final double height;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;
  final bool native;

  @override
  State<NewCircleButton> createState() => _NewCircleButtonState();
}

class _NewCircleButtonState extends State<NewCircleButton> {
  bool _supportsLiquidGlass = false;

  Future<void> _checkLiquidGlassSupport() async {
    final supports = await supportsLiquidGlass();
    setState(() {
      _supportsLiquidGlass = supports;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLiquidGlassSupport();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    if (_supportsLiquidGlass && widget.native) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: CNButton.icon(
          icon: widget.cnIcon,
          onPressed: widget.onPressed,
          tint: widget.color ?? cp.bg,
          config: CNButtonConfig(style: CNButtonStyle.prominentGlass),
        ),
      );
    }

    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Material(
      animationDuration: Duration(milliseconds: isAndroid ? 0 : 200),
      color: widget.color ?? cp.bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: widget.color ?? cp.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(100),
        child: SizedBox(
          height: widget.height,
          width: widget.width,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(13),
            child: SvgPicture.asset(
              widget.svgPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                widget.textColor ?? cp.text,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
