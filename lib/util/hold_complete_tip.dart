import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/default/swipe_up_to_dismiss.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HoldCompleteTip {
  static const _countKey = 'holdCompleteTipCount';
  static const _dismissedKey = 'holdCompleteTipDismissed';
  static OverlayEntry? _entry;

  static Future<void> showIfNeeded(BuildContext context) async {
    if (_entry != null) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dismissedKey) == true) return;

    final count = (prefs.getInt(_countKey) ?? 0) + 1;
    await prefs.setInt(_countKey, count);

    if (count % 10 != 0) return;

    if (!context.mounted) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final cp = context.read<ColorProvider>();
    final loc = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.viewPaddingOf(context).top;

    _entry = OverlayEntry(
      builder:
          (_) => _HoldCompleteTipWidget(
            cp: cp,
            title: loc.holdToCompleteTipTitle,
            body: loc.holdToCompleteTipBody,
            topPadding: topPadding,
            onDismiss: _dismiss,
            onPermanentDismiss: _permanentDismiss,
          ),
    );
    overlay.insert(_entry!);
  }

  static void _dismiss() {
    _entry?.remove();
    _entry = null;
  }

  static Future<void> _permanentDismiss() async {
    _dismiss();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }
}

class _HoldCompleteTipWidget extends StatefulWidget {
  const _HoldCompleteTipWidget({
    required this.cp,
    required this.title,
    required this.body,
    required this.topPadding,
    required this.onDismiss,
    required this.onPermanentDismiss,
  });

  final ColorProvider cp;
  final String title;
  final String body;
  final double topPadding;
  final VoidCallback onDismiss;
  final VoidCallback onPermanentDismiss;

  @override
  State<_HoldCompleteTipWidget> createState() => _HoldCompleteTipWidgetState();
}

class _HoldCompleteTipWidgetState extends State<_HoldCompleteTipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _controller.forward();
    _timer = Timer(const Duration(seconds: 7), _animateOut);
  }

  void _animateOut() {
    if (!mounted) return;
    _controller.reverse().whenComplete(widget.onDismiss);
  }

  void _animateOutPermanent() {
    if (!mounted) return;
    _timer?.cancel();
    _controller.reverse().whenComplete(widget.onPermanentDismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = widget.cp;

    return Positioned(
      top: widget.topPadding + 10,
      left: 16,
      right: 16,
      child: SwipeUpToDismiss(
        onDismiss: _animateOut,
        onDragStart: () => _timer?.cancel(),
        onSettle:
            () => _timer = Timer(const Duration(seconds: 5), _animateOut),
        child: FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.35),
              end: Offset.zero,
            ).animate(_animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(_animation),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: ShapeDecoration(
                    color: cp.field,
                    shape: StadiumBorder(),
                    shadows: [
                      BoxShadow(
                        color: cp.bg.withValues(alpha: 0.6),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    spacing: 12,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cp.main.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            cp.isDark
                                ? 'assets/images/new-svg/check-on-dark.svg'
                                : 'assets/images/new-svg/check-on-light.svg',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 2,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                color: cp.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.body,
                              style: TextStyle(
                                color: cp.lightGreyText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _animateOutPermanent,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: cp.border,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close,
                              size: 13,
                              color: cp.lightGreyText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
