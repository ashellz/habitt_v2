import 'package:flutter/material.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/widgets/glass_feel_container.dart';
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

    Color getColor(bool selected) {
      if (selected) {
        final prefsProvider = context.read<PreferencesProvider>();
        final colorfulness = prefsProvider.colorfulness;
        if (colorfulness == Colorfulness.tinted) {
          return tp.primaryColor;
        }
        return tp.successColor;
      } else {
        return Colors.transparent;
      }
    }

    return GlassFeelContainer(
      padding: const EdgeInsets.all(4),

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
                decoration: ShapeDecoration(
                  color: getColor(selected),
                  shape: StadiumBorder(),
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
