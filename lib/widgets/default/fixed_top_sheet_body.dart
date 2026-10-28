import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/scroll_edge_fade.dart';
import 'package:provider/provider.dart';

// body of a bottom sheet: [topBar] (back / title / save) stays at the top while
// [child] scrolls underneath it, with soft fades at the scrolled edges
// (see ScrollEdgeFade)
// needs a bounded height, put it inside the sheet's ConstrainedBox
class FixedTopSheetBody extends StatelessWidget {
  const FixedTopSheetBody({
    super.key,
    required this.topBar,
    required this.child,
    this.controller,
    this.topPadding = 20,
    this.topBarBottomPadding = 10,
    this.bottomPadding = 28,
    this.fadeExtent = 32,
  });

  final Widget topBar;
  final Widget child;
  final ScrollController? controller;
  final double topPadding;

  // gap between the top bar and the scrolling content
  final double topBarBottomPadding;
  final double bottomPadding;

  // longer than the default ScrollEdgeFade: the first items of a sheet are
  // mostly text and low contrast fields, which a short fade barely shows
  final double fadeExtent;

  @override
  Widget build(BuildContext context) {
    // the sheets are shown on this colour (see showModalBottomSheet callers)
    final sheetColor = context.select<ColorProvider, Color>(
      (cp) => cp.isDark ? cp.habitBg : cp.bg,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: topPadding,
            bottom: topBarBottomPadding,
          ),
          child: topBar,
        ),
        Flexible(
          child: ScrollEdgeFade(
            fadeExtent: fadeExtent,
            startOverlayColor: sheetColor,
            child: SingleChildScrollView(
              controller: controller,
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
