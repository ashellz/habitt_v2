import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/main_pages/calendar_page.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/pages/main_pages/settings_page.dart';
import 'package:habitt/pages/main_pages/stats_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:provider/provider.dart';
/*
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

    final categoryProvider = context.read<CategoryProvider>();

    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Update last opened date, reset habit completion
        await updateLastOpenedDate(context.read<HabitProvider>());
        categoryProvider.reorderCategoriesBasedOnTime();
      });
    }
  }

  // Do the same thing on initialization
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Update last opened date, reset habit completion
      await updateLastOpenedDate(context.read<HabitProvider>());
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
*/

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentPageIndex = 0;

  final List<Widget> _pages = const [
    HabitsPage(),
    CalendarPage(),
    StatsPage(),
    SettingsPage(),
  ];

  // Check if app state has changed, therefore run _updateLastOpenedDate
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final categoryProvider = context.read<CategoryProvider>();

    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Update last opened date, reset habit completion
        await updateLastOpenedDate(context.read<HabitProvider>());
        categoryProvider.reorderCategoriesBasedOnTime();
      });
    }
  }

  // Do the same thing on initialization
  @override
  void initState() {
    super.initState();

    final List<NavItemData> tempNavItemsForIndex = [
      NavItemData(id: 'habits', svgPath: "...", defaultLabel: "Habits"),
      NavItemData(id: 'calendar', svgPath: "...", defaultLabel: "Calendar"),
      NavItemData(id: 'stats', svgPath: "...", defaultLabel: "Stats"),
      NavItemData(id: 'settings', svgPath: "...", defaultLabel: "Settings"),
    ];
    int initialIndex = tempNavItemsForIndex.indexWhere(
      (item) => item.defaultLabel == "Habits",
    );
    if (initialIndex != -1) {
      _currentPageIndex = initialIndex;
    } else {
      _currentPageIndex = 0; // Fallback
    }

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Update last opened date, reset habit completion
      await updateLastOpenedDate(context.read<HabitProvider>());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPageChangedByNavBar(int index) {
    if (index == 0 && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (_currentPageIndex != index) {
      setState(() {
        _currentPageIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Stack(
        children: <Widget>[
          //Page
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: IndexedStack(
              key: ValueKey<int>(_currentPageIndex),
              index: _currentPageIndex,
              children: _pages,
            ),
          ),

          // Floating nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BottomNavBar(onItemTapped: _onPageChangedByNavBar),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NavItemData {
  NavItemData({
    required this.id,
    required this.svgPath,
    required this.defaultLabel,
  });

  final String id;
  final String svgPath;
  final String defaultLabel;
}

class BottomNavBar extends StatefulWidget {
  final ValueChanged<int>? onItemTapped;

  const BottomNavBar({super.key, this.onItemTapped});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  late final List<NavItemData> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = [
      NavItemData(
        id: 'habits',
        svgPath: "assets/images/svg/habits.svg",
        defaultLabel: "Habits",
      ),
      NavItemData(
        id: 'calendar',
        svgPath: "assets/images/svg/calendar.svg",
        defaultLabel: "Calendar",
      ),
      NavItemData(
        id: 'stats',
        svgPath: "assets/images/svg/stats.svg",
        defaultLabel: "Stats",
      ),
      NavItemData(
        id: 'settings',
        svgPath: "assets/images/svg/settings.svg",
        defaultLabel: "Settings",
      ),
    ];

    _selectedIndex = _navItems.indexWhere(
      (item) => item.defaultLabel == "Habits",
    );

    if (_selectedIndex == -1) {
      _selectedIndex = 0;
    }
  }

  Widget _buildNavItem(int index) {
    final colorProvider = context.watch<ColorProvider>();

    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() {
            _selectedIndex = index;
          });
        }
        widget.onItemTapped?.call(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: ShapeDecoration(
          color:
              isSelected
                  ? colorProvider.colorScheme.darkerStandardColor
                  : colorProvider.standardColor.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: SvgPicture.asset(
                item.svgPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  colorProvider.textColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    axisAlignment: -1.0,
                    child: child,
                  ),
                );
              },
              child:
                  isSelected
                      ? DefaultTextStyle(
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        child: Padding(
                          key: ValueKey<String>("text_${item.id}"),
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(item.defaultLabel),
                        ),
                      )
                      : SizedBox.shrink(
                        key: ValueKey<String>("empty_${item.id}"),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 62,
          padding: const EdgeInsets.all(8),
          decoration: ShapeDecoration(
            color: colorProvider.colorScheme.standardColor.withOpacity(0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_navItems.length, (index) {
              Widget navItemWidget = _buildNavItem(index);
              if (index > 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: navItemWidget,
                );
              }
              return navItemWidget;
            }),
          ),
        ),
      ),
    );
  }
}
