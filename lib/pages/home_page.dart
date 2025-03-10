import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/main%20pages/calendar_page.dart';
import 'package:habitt/pages/main%20pages/habits_page.dart';
import 'package:habitt/pages/main%20pages/settings_page.dart';
import 'package:habitt/pages/main%20pages/stats_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          selectedLabelStyle: const TextStyle(
            fontFamily: "PP Neue Montreal",
            color: Color(0xFF212121),
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: "PP Neue Montreal",
            color: Color(0xFF212121),
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
                child: SvgPicture.asset(
                  key: ValueKey<bool>(_currentIndex == 0),
                  _currentIndex == 0
                      ? "assets/images/svg/task-selected.svg"
                      : "assets/images/svg/task-unselected.svg",
                ),
              ),
              label: localizations.habits,
            ),
            BottomNavigationBarItem(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: SvgPicture.asset(
                  key: ValueKey<bool>(_currentIndex == 1),
                  _currentIndex == 1
                      ? "assets/images/svg/dashboard-selected.svg"
                      : "assets/images/svg/dashboard-unselected.svg",
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
                child: SvgPicture.asset(
                  key: ValueKey<bool>(_currentIndex == 2),
                  _currentIndex == 2
                      ? "assets/images/svg/favorite-selected.svg"
                      : "assets/images/svg/favorite-unselected.svg",
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
                child: SvgPicture.asset(
                  key: ValueKey<bool>(_currentIndex == 3),
                  _currentIndex == 3
                      ? "assets/images/svg/settings-selected.svg"
                      : "assets/images/svg/settings-unselected.svg",
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
