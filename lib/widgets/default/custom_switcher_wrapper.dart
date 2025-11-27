import 'package:flutter/material.dart';

class CustomSwitcherWrapper extends StatefulWidget {
  const CustomSwitcherWrapper({
    super.key,
    required this.value,
    required this.widget,
    this.secondaryWidget,
    this.delay = const Duration(milliseconds: 0),
  });

  final bool value;
  final Widget widget;
  final Widget? secondaryWidget;
  final Duration delay;

  @override
  State<CustomSwitcherWrapper> createState() => _CustomSwitcherWrapperState();
}

class _CustomSwitcherWrapperState extends State<CustomSwitcherWrapper> {
  bool _displayedValue = false;

  @override
  void initState() {
    super.initState();
    _displayedValue = widget.value;
  }

  @override
  void didUpdateWidget(CustomSwitcherWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.delay.inMilliseconds > 0) {
        Future.delayed(widget.delay, () {
          if (mounted) {
            setState(() {
              _displayedValue = widget.value;
            });
          }
        });
      } else {
        setState(() {
          _displayedValue = widget.value;
        });
      }
    }
  }

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
      child:
          _displayedValue
              ? widget.widget
              : (widget.secondaryWidget ?? const SizedBox.shrink()),
    );
  }
}
