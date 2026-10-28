import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

/// An SVG whose Habitt-green parts follow the selected theme's accent. For the
/// icons that have the brand green baked in (check marks, the arrow); the
/// colours are swapped when the file loads, so no asset is duplicated per theme.
class AccentSvg extends StatelessWidget {
  const AccentSvg(this.assetName, {super.key, this.width, this.height});

  final String assetName;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final accent = context.select<ColorProvider, Color>((cp) => cp.main);

    return SvgPicture.asset(
      assetName,
      width: width,
      height: height,
      colorMapper: _AccentColorMapper(accent),
    );
  }
}

class _AccentColorMapper extends ColorMapper {
  const _AccentColorMapper(this.accent);

  final Color accent;

  // light and dark brand greens as baked into the assets
  static const Set<int> _brandGreens = {0xFF02D382, 0xFF11F29B};

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => _brandGreens.contains(color.toARGB32()) ? accent : color;

  // flutter_svg caches by loader, so equal accents must share one entry
  @override
  bool operator ==(Object other) =>
      other is _AccentColorMapper && other.accent == accent;

  @override
  int get hashCode => accent.hashCode;
}
