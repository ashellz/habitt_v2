import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/settings/appearance_setting.dart';
import 'package:habitt/widgets/settings/language_setting.dart';
import 'package:habitt/widgets/settings/preferences_settings.dart';
import 'package:habitt/widgets/settings/settings_top_section.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Scaffold(
      body: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: double.infinity,
        height: double.infinity,
        color: cp.isDark ? cp.bg : cp.habitBg,
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20),
        child: ListView(
          children: [
            SettingsTopSection(),
            Padding(
              padding: EdgeInsets.only(top: 26),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 10,
                children: [
                  LanguageSetting(),
                  AppearanceSetting(),
                  Preferences(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
