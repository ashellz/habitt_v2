import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/widgets/gradient_background.dart';
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
    final prefsProvider = context.watch<PreferencesProvider>();

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
        body: GradientBackground(
          child: Padding(
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
                  title: "Dark Mode",
                  desc: "Change a color theme for your interface",
                  iconData: Icons.dark_mode,
                  hasSwitch: true,
                  switchValue: colorProvider.isDarkMode,
                  onTap: () {
                    colorProvider.changeMode();
                  },
                ),

                SettingTile(
                  title: "Glass Feel",
                  desc: "Makes widgets look more glassy",
                  iconData: Icons.blur_on,
                  hasSwitch: true,
                  switchValue: prefsProvider.glassFeel,
                  onTap: () {
                    prefsProvider.toggleGlassFeel();
                  },
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1.0,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child:
                      prefsProvider.glassFeel
                          ? SettingTile(
                            key: const ValueKey("glass_habits_tile"),
                            title: "Glass Habits",
                            desc: "Adds glassy feel to habits too",
                            iconData: Icons.blur_on,
                            hasSwitch: true,
                            switchValue: prefsProvider.glassHabits,
                            onTap: () {
                              prefsProvider.toggleGlassHabits();
                            },
                          )
                          : const SizedBox.shrink(key: ValueKey("empty_tile")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
