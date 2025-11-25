import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 38,
  }) : assert(segments.length > 1);

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tp.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tp.borderColor, width: 2),
      ),
      child: Row(
        children: List.generate(segments.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? tp.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color:
                        selected ? tp.onPrimaryTextColor : tp.primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                  child: Text(segments[i]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
