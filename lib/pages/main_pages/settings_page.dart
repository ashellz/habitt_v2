import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Scaffold(
      backgroundColor: colorProvider.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            Text(
              "Settings",
              style: TextStyle(
                fontSize: 38,
                color: colorProvider.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorProvider.standardColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Change color",
                      style: TextStyle(color: colorProvider.textColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (colorProvider.colorSchemeString == "blue") {
                          colorProvider.changeColorScheme("teal");
                        } else if (colorProvider.colorSchemeString == "teal") {
                          colorProvider.changeColorScheme("green");
                        } else if (colorProvider.colorSchemeString == "green") {
                          colorProvider.changeColorScheme("magenta");
                        } else {
                          colorProvider.changeColorScheme("blue");
                        }
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorProvider.colorScheme.vividColor,
                          border: Border.all(
                            color: colorProvider.colorScheme.strokeColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorProvider.standardColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Change mode",
                      style: TextStyle(color: colorProvider.textColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        colorProvider.changeMode();
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorProvider.standardColor,
                          border: Border.all(
                            color: colorProvider.colorScheme.strokeColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
