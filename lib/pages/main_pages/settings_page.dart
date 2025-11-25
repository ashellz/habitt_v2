import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/widgets/default_annotated_region.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/settings/select_color_sheet.dart';
import 'package:habitt/widgets/segmented_control.dart';
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
    final prefsProvider = context.watch<PreferencesProvider>();
    final tp = context.watch<ThemeProvider>();

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              children: [
                const SizedBox(height: 48),
                Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 38,
                    color: tp.primaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SettingTile(
                  title: "Dark Mode",
                  desc: "Change a color theme for your interface",
                  iconData: Icons.dark_mode,
                  hasSwitch: true,
                  switchValue: tp.isDark,
                  onTap: () {
                    tp.setMode(tp.isDark ? ThemeMode.light : ThemeMode.dark);
                  },
                ),
                SettingTile(
                  title: "Accent Color",
                  desc: "Select a color pallete for your interface",
                  iconData: Icons.color_lens,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      enableDrag: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SelectColorSheet(tp: tp),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.colorize, color: tp.primaryColor, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Colorful Interface",
                              style: TextStyle(
                                color: tp.primaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "Choose how colorful the UI should be",
                              style: TextStyle(color: tp.primaryTextColor),
                            ),
                            const SizedBox(height: 8),
                            SegmentedControl(
                              segments: const [
                                'Tinted',
                                'Standard',
                                'Colorful',
                              ],
                              selectedIndex: prefsProvider.colorfulness.index,
                              onChanged: (i) {
                                prefsProvider.setColorfulness(i);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
