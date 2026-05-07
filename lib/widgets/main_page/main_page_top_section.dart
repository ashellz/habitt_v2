import 'package:cupertino_native_better/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:habitt/pages/main_pages/settings_page.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:habitt/widgets/main_page/last_week_progress.dart';
import 'package:habitt/widgets/main_page/new_perfect_days_streak.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPageTopSection extends StatefulWidget {
  const MainPageTopSection({super.key});

  @override
  State<MainPageTopSection> createState() => _MainPageTopSectionState();
}

class _MainPageTopSectionState extends State<MainPageTopSection>
    with AutomaticKeepAliveClientMixin<MainPageTopSection> {
  String? name;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Loading name
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        name = prefs.getString('name');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        spacing: 20,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Greeting(),
                NewCircleButton(
                  svgPath: "assets/images/new-svg/settings.svg",
                  cnIcon: CNSymbol("gearshape", size: 16),

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          LastWeekProgress(), // 79
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: NewPerfectDaysStreak(),
          ), // 82
        ],
      ),
    );
  }
}

// MediaQuery.of(context).padding.top - top safe area
// 20 - top padding
// 60/40 - spacing
// 79 - LastWeekProgress
// 82 - NewPerfectDaysStreak
// 20 - bottom padding
// if has bigger streak
// TOPPADDING + 20 + 60 + 79 + 82 + 20
// else
// 20 + 40 + 79 + 20
