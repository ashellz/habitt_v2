import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/settings/select_color_sheet.dart';
import 'package:habitt/widgets/settings/setting_tile.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: colorProvider.backgroundColor,
        statusBarIconBrightness:
            colorProvider.isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            colorProvider.isDarkMode
                ? Brightness.dark
                : Brightness.light, // for iOS
      ),
      child: Scaffold(
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

              SettingTile(
                colorProvider: colorProvider,
                title: "Accent Color",
                desc: "Select a color pallete for your interface",
                iconData: Icons.color_lens,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (context) =>
                            SelectColorSheet(colorProvider: colorProvider),
                  );
                },
              ),
              SettingTile(
                colorProvider: colorProvider,
                title: "App Theme",
                desc: "Select a color theme for your interface",
                iconData: Icons.light_mode,
                hasSwitch: true,
                switchValue: !colorProvider.isDarkMode,
                onTap: () {
                  colorProvider.changeMode();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
