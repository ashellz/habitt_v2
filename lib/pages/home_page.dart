import 'package:flutter/material.dart';
import 'package:habitt/pages/main_pages/calendar_page.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/pages/main_pages/settings_page.dart';
import 'package:habitt/pages/main_pages/stats_page.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:habitt/widgets/bottom_nav_bar.dart';
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
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
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
