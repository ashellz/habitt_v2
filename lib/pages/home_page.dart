import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/main_pages/calendar_page.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/pages/main_pages/settings_page.dart';
import 'package:habitt/pages/main_pages/stats_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/get_capitalized_first.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HabitsPage(),
    CalendarPage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorProvider = context.watch<ColorProvider>();
    final Color darkerStandardColor =
        colorProvider.colorScheme.darkerStandardColor;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        transitionBuilder:
            (child, animation) =>
                FadeTransition(opacity: animation, child: child),
        child: _widgetOptions.elementAt(_currentIndex),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(
            color: darkerStandardColor,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            color: Color(0xFF212529),
            fontSize: 12,
          ),
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: SizedBox(
                  key: ValueKey<bool>(_currentIndex == 0),
                  height: 20,
                  width: 20,
                  child: SvgPicture.asset(
                    "assets/images/svg/habits.svg",
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 0
                          ? darkerStandardColor
                          : Color(0xFF212529),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: capitalizeFirst(localizations.habits),
            ),
            BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: SizedBox(
                  key: ValueKey<bool>(_currentIndex == 1),
                  height: 20,
                  width: 20,
                  child: SvgPicture.asset(
                    "assets/images/svg/calendar.svg",
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 1
                          ? darkerStandardColor
                          : Color(0xFF212529),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: localizations.calendar,
            ),
            BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: SizedBox(
                  key: ValueKey<bool>(_currentIndex == 2),
                  height: 20,
                  width: 20,
                  child: SvgPicture.asset(
                    "assets/images/svg/stats.svg",
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 2
                          ? darkerStandardColor
                          : Color(0xFF212529),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: localizations.stats,
            ),
            BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: SizedBox(
                  key: ValueKey<bool>(_currentIndex == 3),
                  height: 20,
                  width: 20,
                  child: SvgPicture.asset(
                    "assets/images/svg/settings.svg",
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 3
                          ? darkerStandardColor
                          : Color(0xFF212529),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              label: localizations.settings,
            ),
          ],
        ),
      ),
    );
  }
}
