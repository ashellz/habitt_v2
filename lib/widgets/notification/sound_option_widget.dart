import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

/// A single row in the sound picker, styled like [LanguageOptionWidget] but
/// without a leading icon: a pill with the label on the left and an animated
/// check on the right. It owns no selection/preview state — the sheet drives
/// [isSelected] and [onTap].
class SoundOptionWidget extends StatelessWidget {
  const SoundOptionWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    final checkSvgPath =
        cp.isDark
            ? 'assets/images/new-svg/check-on-dark.svg'
            : 'assets/images/new-svg/check-on-light.svg';

    const selectionDuration = Duration(milliseconds: 200);
    const iconTurns = 0.18;

    return SizedBox(
      height: 46,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: isSelected ? cp.main.withValues(alpha: 0.2) : cp.border,
            ),
            borderRadius: BorderRadius.circular(100),
          ),
          color:
              isSelected ? cp.main.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ButtonStyle(
            splashFactory: NoSplash.splashFactory,
            elevation: const WidgetStatePropertyAll(0),
            overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (!states.contains(WidgetState.pressed)) {
                return null;
              }
              return cp.bg.withValues(alpha: 0.2);
            }),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 20,
                height: 20,
                child: AnimatedOpacity(
                  duration: selectionDuration,
                  curve: Curves.easeOut,
                  opacity: isSelected ? 1 : 0,
                  child: AnimatedScale(
                    duration: selectionDuration,
                    curve: Curves.easeOutBack,
                    scale: isSelected ? 1 : 0.7,
                    child: AnimatedRotation(
                      duration: selectionDuration,
                      curve: Curves.easeOutBack,
                      turns: isSelected ? 0 : iconTurns,
                      child: SvgPicture.asset(checkSvgPath),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
