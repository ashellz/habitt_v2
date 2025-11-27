import 'package:flutter/material.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/widgets/default/custom_switcher_wrapper.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/settings/select_color_sheet.dart';
import 'package:habitt/widgets/settings/segmented_control.dart';
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
    bool isTinted = prefsProvider.colorfulness == Colorfulness.tinted;

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
                  icon: CustomSwitcherWrapper(
                    value: isTinted,
                    widget: Icon(
                      Icons.dark_mode,
                      color: tp.primaryColor,
                      size: 32,
                    ),
                    secondaryWidget: Image.asset(
                      "assets/images/icons/moon.png",
                    ),
                  ),
                  hasSwitch: true,
                  switchValue: tp.isDark,
                  onTap: () {
                    tp.setMode(tp.isDark ? ThemeMode.light : ThemeMode.dark);
                  },
                ),
                SettingTile(
                  title: "Accent Color",
                  desc: "Select a color pallete for your interface",
                  icon: CustomSwitcherWrapper(
                    delay: Duration(milliseconds: 100),
                    value: isTinted,
                    widget: Icon(
                      Icons.color_lens,
                      color: tp.primaryColor,
                      size: 32,
                    ),
                    secondaryWidget: Image.asset(
                      "assets/images/icons/color-wheel.png",
                    ),
                  ),
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
                      CustomSwitcherWrapper(
                        delay: Duration(milliseconds: 200),
                        value: isTinted,
                        widget: Icon(
                          Icons.colorize,
                          color: tp.primaryColor,
                          size: 32,
                        ),
                        secondaryWidget: Image.asset(
                          "assets/images/icons/colorful.png",
                          width: 32,
                          height: 32,
                        ),
                      ),
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
                  icon: CustomSwitcherWrapper(
                    delay: Duration(milliseconds: 300),
                    value: isTinted,
                    widget: Icon(
                      Icons.blur_on,
                      color: tp.primaryColor,
                      size: 32,
                    ),
                    secondaryWidget: Image.asset(
                      "assets/images/icons/blur.png",
                      width: 32,
                      height: 32,
                    ),
                  ),
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
                            icon: CustomSwitcherWrapper(
                              delay: Duration(milliseconds: 400),
                              value: isTinted,
                              widget: Icon(
                                Icons.blur_on,
                                color: tp.primaryColor,
                                size: 32,
                              ),
                              secondaryWidget: Image.asset(
                                "assets/images/icons/blur.png",
                                width: 32,
                                height: 32,
                              ),
                            ),
                            desc: "Adds glassy feel to habits too",
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
