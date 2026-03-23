import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class AnimatedCheckbox extends StatefulWidget {
  const AnimatedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 28,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeOut),
    );

    if (widget.value) {
      _gradientController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _gradientController.forward();
      } else {
        _gradientController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final hslMain = HSLColor.fromColor(cp.main);
    final gradientEnd =
        hslMain
            .withLightness((hslMain.lightness - 0.08).clamp(0.0, 1.0))
            .toColor();

    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return AnimatedScale(
          scale: _pressed ? 0.93 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              splashFactory: NoSplash.splashFactory,
              onHighlightChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _pressed = value;
                });
              },
              onTap: () => widget.onChanged(!widget.value),
              child: Ink(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    width: 1,
                    color: widget.value ? cp.main : cp.disabled,
                  ),
                  gradient:
                      _gradientAnimation.value > 0
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cp.main.withValues(
                                alpha: _gradientAnimation.value,
                              ),
                              gradientEnd.withValues(
                                alpha: _gradientAnimation.value,
                              ),
                            ],
                          )
                          : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.55, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            ),
                          ),
                          child: RotationTransition(
                            turns: Tween<double>(begin: -0.06, end: 0).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOut,
                              ),
                            ),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child:
                        widget.value
                            ? SvgPicture.asset(
                              "assets/images/new-svg/check.svg",
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                cp.bg,
                                BlendMode.srcIn,
                              ),
                            )
                            : SizedBox(
                              key: const ValueKey('unchecked'),
                              width: 24,
                              height: 24,
                            ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
