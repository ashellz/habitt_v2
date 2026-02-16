import 'package:cupertino_native/components/button.dart';
import 'package:cupertino_native/style/button_style.dart';
import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/util/supports_liquid_glass.dart';
import 'package:provider/provider.dart';

class NewCircleButton extends StatefulWidget {
  const NewCircleButton({
    super.key,
    required this.svgPath,
    required this.cnIcon,
    this.onPressed,
  });

  final String svgPath;
  final CNSymbol cnIcon;
  final VoidCallback? onPressed;

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

    if (_supportsLiquidGlass) {
      return SizedBox(
        height: 46,
        width: 46,
        child: CNButton.icon(
          icon: widget.cnIcon,
          onPressed: widget.onPressed,
          tint: cp.text,
          style: CNButtonStyle.prominentGlass,
        ),
      );
    }

    return Material(
      color: cp.bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(width: 1, color: cp.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(100),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: SvgPicture.asset(
              widget.svgPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
