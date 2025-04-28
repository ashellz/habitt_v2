import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/main_pages/calendar_page.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/pages/main_pages/settings_page.dart';
import 'package:habitt/pages/main_pages/stats_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/get_capitalized_first.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // Check if app state has changed, therefore run _updateLastOpenedDate
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        updateLastOpenedDate(context.read<HabitProvider>());
      });
    }
  }

  // Do the same thing on initialization
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      updateLastOpenedDate(context.read<HabitProvider>());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
    final Color vividColor = colorProvider.colorScheme.vividColor;

    return Scaffold(
      backgroundColor: colorProvider.backgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        transitionBuilder:
            (child, animation) =>
                FadeTransition(opacity: animation, child: child),
        child: _widgetOptions.elementAt(_currentIndex),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: colorProvider.backgroundColor,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: vividColor,
          unselectedItemColor: colorProvider.textColor,
          selectedLabelStyle: TextStyle(fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 12),
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
                      _currentIndex == 0 ? vividColor : colorProvider.textColor,
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
                      _currentIndex == 1 ? vividColor : colorProvider.textColor,
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
                      _currentIndex == 2 ? vividColor : colorProvider.textColor,
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
                      _currentIndex == 3 ? vividColor : colorProvider.textColor,
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

Future<void> updateLastOpenedDate(HabitProvider habitProvider) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  DateTime lastOpenedDate;

  debugPrint("Running _updateLastOpenedDate");

  // I check if user has lastOpenedDate
  final temp = prefs.getString("lastOpenedDate");
  debugPrint("temp: $temp");
  if (temp == null) {
    // If not, I set it to now
    lastOpenedDate = DateTime.now();
    final DateTime today = DateTime.now();
    prefs.setString("lastOpenedDate", today.toString());
  } else {
    // Else I set it to old one
    lastOpenedDate = DateTime.parse(temp);
    lastOpenedDate = DateTime.now().add(Duration(days: 1));
    // I check for new day
    checkForNewDay(prefs, lastOpenedDate, habitProvider);
  }
}

void checkForNewDay(
  SharedPreferences prefs,
  DateTime lastOpenedDate,
  habitProvider,
) {
  DateTime today = DateTime.now();

  if (lastOpenedDate.day != today.day) {
    // Before updating lastOpenedDate, I update daysBox with that date
    habitProvider.saveHabitDay(today);

    //Now we reset habit status (completion, amountCompleted, durationCompleted)
    habitProvider.resetCompletion();
    // If new day, we now can update lastOpenedDate
    today = today.subtract(Duration(days: 1));
    prefs.setString("lastOpenedDate", today.toString());
  }
}
