import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/other_pages/notification_settings_page.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class Preferences extends StatelessWidget {
  const Preferences({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Text(
          'Preferences',
          textAlign: TextAlign.start,
          style: TextStyle(color: cp.lightGreyText, fontSize: 16),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NotificationSettingsPage()),
            );
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
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
              children: [
                Container(
                  height: 32,
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          color: cp.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      RotatedBox(
                        quarterTurns: 2,
                        child: SvgPicture.asset(
                          'assets/images/new-svg/back.svg',
                          colorFilter: ColorFilter.mode(
                            cp.text,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                /*
                Divider(color: cp.border, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '12-hour format',
                      style: TextStyle(
                        color: cp.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    NewDefaultSwitch(
                      onChanged: (value) {
                        context
                            .read<PreferencesProvider>()
                            .toggleAmericanTimeFormat();
                      },
                      value:
                          context.watch<PreferencesProvider>().americanTimeFormat,
                    ),
                  ],
                ), */
              ],
            ),
          ),
        ),
      ],
    );
  }
}
