import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';

class StatusOverlayPopupController {
  StatusOverlayPopupController({required TickerProvider vsync})
    : _vsync = vsync;

  final TickerProvider _vsync;
  OverlayEntry? _overlayEntry;
  Timer? _overlayTimer;
  AnimationController? _overlayController;

  void dispose() {
    _removeOverlay();
  }

  void _removeOverlay() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _overlayController?.dispose();
    _overlayController = null;
  }

  void show({
    required BuildContext context,
    required ColorProvider cp,
    required String title,
    required bool isError,
    String? iconPath,
    Widget? iconWidget,
    Color? iconColor,
  }) {
    _removeOverlay();

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay.mounted == false) {
      return;
    }

    final controller = AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 450),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _overlayController = controller;

    final resolvedIconPath =
        iconPath ??
        (isError
            ? 'assets/images/new-svg/skipped.svg'
            : (cp.isDark
                ? 'assets/images/new-svg/check-on-dark.svg'
                : 'assets/images/new-svg/check-on-light.svg'));

    final accent = isError ? cp.fail : cp.main;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    final entry = OverlayEntry(
      builder: (overlayContext) {
        final topPadding = MediaQuery.viewPaddingOf(overlayContext).top;
        return Positioned(
          top: topPadding + 10,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.35),
                    end: Offset.zero,
                  ).animate(animation),
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.94,
                      end: 1,
                    ).animate(animation),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: ShapeDecoration(
                          color: cp.field,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 1,
                              color: accent.withValues(alpha: 0.35),
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  iconWidget ??
                                  SvgPicture.asset(
                                    resolvedIconPath,
                                    colorFilter:
                                        iconColor != null
                                            ? ColorFilter.mode(
                                              iconColor,
                                              BlendMode.srcIn,
                                            )
                                            : null,
                                  ),
                            ),
                            Text(
                              title,
                              style: TextStyle(
                                color: cp.text,
                                fontSize: 13,
                                fontFamily: 'Satoshi',
                                fontWeight: FontWeight.w400,
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
          ),
        );
      },
    );

    _overlayEntry = entry;
    overlay.insert(entry);
    controller.forward();

    _overlayTimer = Timer(const Duration(milliseconds: 1800), () {
      if (_overlayController != controller) {
        return;
      }

      controller.reverse().whenComplete(() {
        if (_overlayController != controller) {
          return;
        }
        _removeOverlay();
      });
    });
  }
}
