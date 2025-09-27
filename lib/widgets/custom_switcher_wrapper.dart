import 'package:flutter/material.dart';

class CustomSwitcherWrapper extends StatelessWidget {
  const CustomSwitcherWrapper({
    super.key,
    required this.value,
    required this.widget,
  });

  final bool value;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 0.2),
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: value ? widget : const SizedBox.shrink(),
    );
  }
}
