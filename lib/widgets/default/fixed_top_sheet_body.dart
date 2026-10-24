import 'package:flutter/material.dart';
import 'package:habitt/widgets/default/fading_scroll_view.dart';

// body of a bottom sheet: [topBar] (back / title / save) stays at the top while
// [child] scrolls underneath it, with soft fades at the scrolled edges
// (see FadingScrollView)
// needs a bounded height, put it inside the sheet's ConstrainedBox
class FixedTopSheetBody extends StatelessWidget {
  const FixedTopSheetBody({
    super.key,
    required this.topBar,
    required this.child,
    this.controller,
    this.topPadding = 20,
    this.bottomPadding = 28,
  });

  final Widget topBar;
  final Widget child;
  final ScrollController? controller;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: EdgeInsets.only(top: topPadding), child: topBar),
        Flexible(
          child: FadingScrollView(
            controller: controller,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: child,
          ),
        ),
      ],
    );
  }
}
