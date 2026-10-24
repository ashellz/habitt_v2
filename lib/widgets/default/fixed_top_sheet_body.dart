import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

// body of a bottom sheet: [topBar] (back / title / save) stays at the top while
// [child] scrolls underneath it. Once the content has scrolled, a short fade
// softens its edge under the bar.
// needs a bounded height, put it inside the sheet's ConstrainedBox
//
// the fade is a plain gradient on purpose: a BackdropFilter blur re-blurs the
// scrolling content every frame and made sheets laggy
class FixedTopSheetBody extends StatefulWidget {
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

  static const double fadeHeight = 16;

  @override
  State<FixedTopSheetBody> createState() => _FixedTopSheetBodyState();
}

class _FixedTopSheetBodyState extends State<FixedTopSheetBody> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    // only this sheet's own vertical scroll, not scrollables inside the content
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final scrolled = notification.metrics.pixels > 0;
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final background = cp.isDark ? cp.habitBg : cp.bg;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: widget.topPadding),
          child: widget.topBar,
        ),
        Flexible(
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: SingleChildScrollView(
                  controller: widget.controller,
                  padding: EdgeInsets.only(bottom: widget.bottomPadding),
                  child: widget.child,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: FixedTopSheetBody.fadeHeight,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: _scrolled ? 1 : 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [background, background.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
