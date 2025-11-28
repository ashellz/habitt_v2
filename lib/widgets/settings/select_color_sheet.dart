import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/color_service.dart';
import 'package:tinycolor2/tinycolor2.dart';

/// Bottom sheet for selecting accent / interface color palette.
/// Layout matches SelectHabitColorSheet: scrollable up to 90% height,
/// rounded top corners, border, and internal wrap of swatches.
class SelectColorSheet extends StatelessWidget {
  const SelectColorSheet({super.key, required this.tp});

  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.9; // allow up to 90% of screen

    final Map<String, AccentPalette> palettes =
        tp.isDark ? ColorService.accentDark : ColorService.accentLight;

    final sheet = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tp.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(color: tp.borderColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            'Select color',
            style: TextStyle(
              color: tp.primaryTextColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final entry in palettes.entries)
                  GestureDetector(
                    onTap: () async {
                      await tp.setAccent(entry.key);
                      Navigator.of(context).pop();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: entry.value.primary,
                        border:
                            tp.accentName == entry.key
                                ? Border.all(
                                  color:
                                      tp.isDark
                                          ? entry.value.primary.lighten(20)
                                          : entry.value.primary.darken(20),
                                  width: 3,
                                )
                                : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: sheet,
          ),
        );
      },
    );
  }
}
