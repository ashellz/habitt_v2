import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:habitt/widgets/main_page/last_week_progress.dart';
import 'package:provider/provider.dart';
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
          LastWeekProgress(),
          const PerfectDaysStreak(),
        ],
      ),
    );
  }
}

class PerfectDaysStreak extends StatelessWidget {
  const PerfectDaysStreak({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final statsProvider = context.watch<StatsProvider>();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Colors.white,
          ),
          borderRadius: BorderRadius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            clipBehavior: Clip.antiAlias,
            height: 82,
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment(1.00, 0.00),
                end: Alignment(0.00, 1.00),
                colors: [cp.leftOrangeGraident, cp.rightOrangeGradient],
              ),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignOutside,
                  color: Colors.white,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: Row(
              spacing: 12,
              children: [
                Text(
                  statsProvider.perfectDaysStreak.toString(),
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      'Days Streak',
                      style: TextStyle(
                        color: cp.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'You are doing really great!',
                      style: TextStyle(
                        color: cp.text.withValues(alpha: 0.60),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -20,
            right: -40,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.45,
              height: MediaQuery.of(context).size.width * 0.45,
              decoration: ShapeDecoration(
                gradient: RadialGradient(
                  colors: [
                    cp.orange.withOpacity(0.9),
                    cp.orange.withOpacity(0),
                  ],
                ),
                shape: OvalBorder(),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 0,
            child: SvgPicture.asset(
              "assets/images/new-svg/streak.svg",
              width: 94,
              height: 94,
            ),
          ),
        ],
      ),
    );
  }
}
