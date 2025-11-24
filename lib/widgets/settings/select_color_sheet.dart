/*
import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';

class SelectColorSheet extends StatelessWidget {
  const SelectColorSheet({super.key, required this.tp});

  final ThemeProvider tp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tp.backgroundColor,
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
            "Select color",
            style: TextStyle(
              color: tp.primaryTextColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Divider(thickness: 2, color: tp.colorScheme.strokeColor),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final colorScheme in tp.colorSchemes)
                      GestureDetector(
                        onTap: () {
                          tp.changeColorScheme(colorScheme.name);
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
                            color: tp.,
                            border:
                                tp.colorScheme == colorScheme
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
*/
