import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

/// Previous / next arrows with the page dots between them.
class WhatsNewPagerControls extends StatelessWidget {
  const WhatsNewPagerControls({
    super.key,
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
    required this.previousLabel,
    required this.nextLabel,
  });

  final int index;
  final int count;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String previousLabel;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          label: previousLabel,
          onPressed: index > 0 ? onPrevious : null,
        ),
        Row(
          spacing: 6,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: i == index ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == index ? cp.main : cp.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
          ],
        ),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          label: nextLabel,
          onPressed: index < count - 1 ? onNext : null,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.35,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cp.border, width: 1),
            ),
            child: Icon(icon, size: 26, color: cp.text),
          ),
        ),
      ),
    );
  }
}
