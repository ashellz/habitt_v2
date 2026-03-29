import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/services/color_service.dart';
import 'package:habitt/widgets/settings/language_setting.dart';
import 'package:habitt/widgets/settings/settings_top_section.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _kAnimDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    void setMode(ColorMode mode) {
      if (cp.mode != mode) {
        cp.setMode(mode);
      }
    }

    Widget modeOption({
      required String label,
      required ColorMode mode,
      required Widget preview,
    }) {
      final selected = cp.mode == mode;

      return Expanded(
        child: GestureDetector(
          onTap: () => setMode(mode),
          behavior: HitTestBehavior.opaque,
          child: Column(
            spacing: 10,
            children: [
              Container(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignInside,
                      color: selected ? cp.main : Colors.transparent,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: preview,
                ),
              ),
              AnimatedContainer(
                duration: _kAnimDuration,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: ShapeDecoration(
                  color:
                      selected
                          ? cp.main.withValues(alpha: 0.1)
                          : Colors.transparent,
                  shape: StadiumBorder(
                    side: BorderSide(
                      width: 1,
                      color:
                          selected
                              ? cp.main.withValues(alpha: 0.2)
                              : Colors.transparent,
                    ),
                  ),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: _kAnimDuration,
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: selected ? cp.main : cp.lightGreyText,
                    fontSize: 16,
                  ),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget previewCard({required bool dark, required bool split}) {
      const lUp = Light.habitsBg;
      const lUpWidget = Light.disabled;
      const lDownWidget = Light.border;
      const lDownContainer = Colors.white;
      const lDown = Color(0xFFD1D1D1);

      const dUp = Color(0xFF383838);
      const dUpWidget = Color(0xFF585858);
      const dDownWidget = Color(0xFF6C6C6C);
      const dDownContainer = Color(0xFF9D9D9D);
      const dDown = Colors.black;

      return SizedBox(
        width: 70,
        height: 94,
        child: Stack(
          children: [
            // Background
            Column(
              children: [
                // Top background
                SizedBox(
                  height: 41,
                  child: Row(
                    children: [
                      // Top left background
                      Expanded(
                        child: Container(
                          height: 41,
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                              ),
                            ),
                            color:
                                split
                                    ? lUp
                                    : dark
                                    ? dUp
                                    : lUp,
                          ),
                        ),
                      ),
                      // Top right background
                      Expanded(
                        child: Container(
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(16),
                              ),
                            ),
                            color: dark ? dUp : lUp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom background
                SizedBox(
                  height: 53,
                  child: Row(
                    children: [
                      // Bottom left background
                      Expanded(
                        child: Container(
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            color:
                                split
                                    ? lDown
                                    : dark
                                    ? dDown
                                    : lDown,
                          ),
                        ),
                      ),
                      // Bottom right background
                      Expanded(
                        child: Container(
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            color:
                                split
                                    ? dDown
                                    : dark
                                    ? dDown
                                    : lDown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Widgets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                spacing: 4,
                // Top widgets
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(top: 9),
                              height: 9,
                              decoration: ShapeDecoration(
                                color:
                                    split
                                        ? lUpWidget
                                        : dark
                                        ? dUpWidget
                                        : lUpWidget,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(top: 9),
                              height: 9,
                              decoration: ShapeDecoration(
                                color:
                                    split
                                        ? dUpWidget
                                        : dark
                                        ? dUpWidget
                                        : lUpWidget,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 9,
                        width: 27,
                        decoration: ShapeDecoration(
                          color:
                              split
                                  ? lUpWidget
                                  : dark
                                  ? dUpWidget
                                  : lUpWidget,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 54,
                    width: 58,
                    child: Row(
                      children: [
                        SizedBox(
                          height: 54,
                          width: 29,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: ShapeDecoration(
                              color:
                                  split
                                      ? lDownContainer
                                      : dark
                                      ? dDownContainer
                                      : lDownContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.only(
                              left: 5,
                              right: 1.33,
                              top: 6,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2.67,
                              children: [
                                Container(
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        split
                                            ? lDownWidget
                                            : dark
                                            ? dDownWidget
                                            : lDownWidget,
                                  ),
                                ),
                                Container(
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        split
                                            ? lDownWidget
                                            : dark
                                            ? dDownWidget
                                            : lDownWidget,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 54,
                          width: 29,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: ShapeDecoration(
                              color:
                                  split
                                      ? dDownContainer
                                      : dark
                                      ? dDownContainer
                                      : lDownContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                            ),

                            padding: const EdgeInsets.only(
                              right: 5,
                              left: 1.33,
                              top: 6,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2.67,
                              children: [
                                Container(
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        split
                                            ? dDownWidget
                                            : dark
                                            ? dDownWidget
                                            : lDownWidget,
                                  ),
                                ),
                                Container(
                                  height: 10,
                                  width: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        split
                                            ? dDownWidget
                                            : dark
                                            ? dDownWidget
                                            : lDownWidget,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 20),
        child: ListView(
          children: [
            SettingsTopSection(),
            Padding(
              padding: EdgeInsets.only(top: 26),
              child: Column(
                spacing: 10,
                children: [
                  LanguageSetting(),
                  Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: TextStyle(
                          color: cp.lightGreyText,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: cp.isDark ? cp.habitBg : cp.bg,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: cp.border),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Column(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode',
                              style: TextStyle(
                                color: cp.lightGreyText,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Row(
                              spacing: 8,
                              children: [
                                modeOption(
                                  label: 'Light',
                                  mode: ColorMode.light,
                                  preview: previewCard(
                                    dark: false,
                                    split: false,
                                  ),
                                ),
                                modeOption(
                                  label: 'Dark',
                                  mode: ColorMode.dark,
                                  preview: previewCard(
                                    dark: true,
                                    split: false,
                                  ),
                                ),
                                modeOption(
                                  label: 'System',
                                  mode: ColorMode.system,
                                  preview: previewCard(dark: true, split: true),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
