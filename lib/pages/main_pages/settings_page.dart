import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            Text(
              "Settings",
              style: TextStyle(fontSize: 24, color: colorProvider.textColor),
            ),
            ElevatedButton(
              onPressed: () {
                if (colorProvider.colorSchemeString == "blue") {
                  colorProvider.changeColorScheme("green");
                } else {
                  colorProvider.changeColorScheme("blue");
                }
              },
              child: Text("Change color"),
            ),
          ],
        ),
      ),
    );
  }
}
