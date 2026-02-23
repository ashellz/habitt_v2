import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
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

class _MainPageTopSectionState extends State<MainPageTopSection> {
  String? name;

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
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        spacing: 20,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Greeting(),
              NewCircleButton(
                svgPath: "assets/images/new-svg/settings.svg",
                cnIcon: CNSymbol("gearshape", size: 16),

                onPressed: () {
                  Navigator.pushNamed(context, "/settings");
                },
              ),
            ],
          ),
          LastWeekProgress(), // 79
          NewPerfectDaysStreak(), // 82
        ],
      ),
    );
  }
}

// if has bigger streak 60 + 79 + 82 else 40 + 79 + 0
