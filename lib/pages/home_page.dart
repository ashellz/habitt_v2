import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/main_pages/calendar_page.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/pages/main_pages/settings_page.dart';
import 'package:habitt/pages/main_pages/stats_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:habitt/widgets/glass_container.dart';
import 'package:provider/provider.dart';

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

      if (index == 2) {
        // stats page
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final statsProvider = context.read<StatsProvider>();
          statsProvider.refreshStats();
        });
      }
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: SvgPicture.asset(
                item.svgPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  isSelected
                      ? colorProvider.colorScheme.vividColor
                      : colorProvider.textColor.withOpacity(0.9),
                  BlendMode.srcIn,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.horizontal,
                    child: child,
                  ),
                );
              },
              child: DefaultTextStyle(
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color:
                      isSelected
                          ? colorProvider.colorScheme.vividColor
                          : colorProvider.textColor.withOpacity(0.9),
                  fontSize: 12,
                ),
                child: Padding(
                  key: ValueKey<String>("text_${item.id}"),
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(item.defaultLabel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(2),
      height: 64,
      borderRadius: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated pill that goes around the nav bar depending on the selected index
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _selectedIndex * 73.5,
            child: GlassContainer(
              width: 95,
              height: 60,
              color: context.watch<ColorProvider>().standardColor,
              borderRadius: 100,
              borderColor: Colors.transparent,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
        ],
      ),
    );
  }
}

/*
ClipRRect(
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
          child: 
        ),
      ),
    );


Row(
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

 */
