import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

// vertical SingleChildScrollView that softens its top edge once scrolled down
// and its bottom edge while there is more below, with a short gradient in the
// sheet's background colour. Short content that doesn't scroll gets no fade.
//
// the fade is a plain gradient on purpose: a BackdropFilter blur re-blurs the
// scrolling content every frame and made sheets laggy
class FadingScrollView extends StatefulWidget {
  const FadingScrollView({
    super.key,
    required this.child,
    this.controller,
    this.padding,
  });

  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  static const double fadeHeight = 16;
  static const topFadeKey = ValueKey('fading-scroll-view-top');
  static const bottomFadeKey = ValueKey('fading-scroll-view-bottom');

  @override
  State<FadingScrollView> createState() => _FadingScrollViewState();
}

class _FadingScrollViewState extends State<FadingScrollView> {
  bool _fadeTop = false;
  bool _fadeBottom = false;

  // half a pixel of slack so a fully scrolled view doesn't flicker
  static const double _epsilon = 0.5;

  bool _onNotification(Notification notification) {
    // metrics change (first layout, keyboard, content growing) and scrolling
    final ScrollMetrics metrics;
    if (notification is ScrollNotification) {
      metrics = notification.metrics;
    } else if (notification is ScrollMetricsNotification) {
      metrics = notification.metrics;
    } else {
      return false;
    }

    // only this view's own vertical scroll, not scrollables inside the content
    if (notification is ViewportNotificationMixin && notification.depth != 0) {
      return false;
    }
    if (metrics.axis != Axis.vertical) return false;

    final fadeTop = metrics.extentBefore > _epsilon;
    final fadeBottom = metrics.extentAfter > _epsilon;
    if (fadeTop != _fadeTop || fadeBottom != _fadeBottom) {
      setState(() {
        _fadeTop = fadeTop;
        _fadeBottom = fadeBottom;
      });
    }
    return false;
  }

  Widget _fade({
    required Key key,
    required bool visible,
    required Color color,
    required bool atTop,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      top: atTop ? 0 : null,
      bottom: atTop ? null : 0,
      height: FadingScrollView.fadeHeight,
      child: IgnorePointer(
        child: AnimatedOpacity(
          key: key,
          duration: const Duration(milliseconds: 150),
          opacity: visible ? 1 : 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: atTop ? Alignment.topCenter : Alignment.bottomCenter,
                end: atTop ? Alignment.bottomCenter : Alignment.topCenter,
                colors: [color, color.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final background = cp.isDark ? cp.habitBg : cp.bg;

    return Stack(
      children: [
        NotificationListener<Notification>(
          onNotification: _onNotification,
          child: SingleChildScrollView(
            controller: widget.controller,
            padding: widget.padding,
            child: widget.child,
          ),
        ),
        _fade(
          key: FadingScrollView.topFadeKey,
          visible: _fadeTop,
          color: background,
          atTop: true,
        ),
        _fade(
          key: FadingScrollView.bottomFadeKey,
          visible: _fadeBottom,
          color: background,
          atTop: false,
        ),
      ],
    );
  }
}
