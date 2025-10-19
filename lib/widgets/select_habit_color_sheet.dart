import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class SelectHabitColorSheet extends StatelessWidget {
  const SelectHabitColorSheet({super.key, required this.colorProvider});

  final ColorProvider colorProvider;

  @override
  Widget build(BuildContext context) {
    final stateProvider = context.watch<StateProvider>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorProvider.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            "Select habit color",
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
                    for (Color vividColor in colorProvider.vividColors)
                      GestureDetector(
                        onTap: () {
                          stateProvider.habitColor = vividColor;
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
                            color: vividColor,
                            border:
                                stateProvider.habitColor == vividColor
                                    ? Border.all(
                                      color: vividColor.darken(
                                        colorProvider.isDarkMode ? 30 : 15,
                                      ),
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
