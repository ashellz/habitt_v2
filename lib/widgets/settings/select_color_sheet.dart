import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';

class SelectColorSheet extends StatelessWidget {
  const SelectColorSheet({super.key, required this.colorProvider});

  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorProvider.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            "Select color",
            style: TextStyle(
              color: colorProvider.textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Divider(thickness: 2, color: colorProvider.colorScheme.strokeColor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final colorScheme in colorProvider.colorSchemes)
                      GestureDetector(
                        onTap: () {
                          colorProvider.changeColorScheme(colorScheme.name);
                          Navigator.of(context).pop();
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          width: 60,
                          height: 60,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: colorScheme.vividColor,
                            border:
                                colorProvider.colorScheme == colorScheme
                                    ? Border.all(
                                      color: colorScheme.darkerStandardColor,
                                      width: 3,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
