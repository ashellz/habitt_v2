import 'dart:io';

import 'package:flutter/material.dart';
import 'package:habitt/pages/main_pages/main_page.dart';
import 'package:habitt/pages/main_pages/calendar_page.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/pages/main_pages/profile_page.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/util/supports_liquid_glass.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:habitt/widgets/default/new_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentPageIndex = 0;
  bool _supportsLiquidGlass = false;

  final List<Widget> _pages = const [
    MainPage(),
    HabitsPage(),
    CalendarPage(),
    ProfilePage(),
  ];

  // Check if app state has changed, therefore run _updateLastOpenedDate
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final categoryProvider = context.read<CategoryProvider>();

    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final backupProvider = context.read<BackupProvider>();
        // Update last opened date, reset habit completion
        await updateLastOpenedDate(
          context.read<HabitProvider>(),
          context.read<StateProvider>(),
        );
        categoryProvider.reorderCategoriesBasedOnTime();

        await backupProvider.performSync();
      });
    }
  }

  // Do the same thing on initialization
  @override
  void initState() {
    super.initState();

    _checkLiquidGlassSupport();

    final List<NavItemData> tempNavItemsForIndex = [
      NavItemData(id: 'home', svgPath: "...", defaultLabel: "Home"),
      NavItemData(id: 'habits', svgPath: "...", defaultLabel: "Habits"),
      NavItemData(id: 'calendar', svgPath: "...", defaultLabel: "Calendar"),
      NavItemData(id: 'profile', svgPath: "...", defaultLabel: "Profile"),
    ];
    int initialIndex = tempNavItemsForIndex.indexWhere(
      (item) => item.id == 'home',
    );
    if (initialIndex != -1) {
      _currentPageIndex = initialIndex;
    } else {
      _currentPageIndex = 0; // Fallback
    }

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final stateProvider = context.read<StateProvider>();
      final backupProvider = context.read<BackupProvider>();

      // Update last opened date, reset habit completion
      await updateLastOpenedDate(context.read<HabitProvider>(), stateProvider);
      await backupProvider.performSync();

      if (stateProvider.shouldUpdateStreaks && mounted) {
        context.read<HabitProvider>().assignStreaks();
        stateProvider.shouldUpdateStreaks = false;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkLiquidGlassSupport() async {
    final supports = await supportsLiquidGlass();
    setState(() {
      _supportsLiquidGlass = supports;
    });
  }

  void _onPageChangedByNavBar(int index) {
    if (_currentPageIndex != index) {
      final stateProvider = context.read<StateProvider>();

      setState(() {
        _currentPageIndex = index;
      });

      if (index == 2) {
        context.read<StatsProvider>().refreshStats();
      }

      if (stateProvider.shouldUpdateStreaks) {
        context.read<HabitProvider>().assignStreaks();
        stateProvider.shouldUpdateStreaks = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final backupProvider = context.watch<BackupProvider>();
    final loading = backupProvider.syncState == SyncState.syncing;
    final tp = context.watch<ThemeProvider>();

    return SizedBox(
      child: Stack(
        children: <Widget>[
          //Page
          Stack(
            children: [
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
              if (loading)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.withOpacity(0.3),
                    color: tp.primaryTextColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      tp.primaryTextColor,
                    ),
                  ),
                ),
            ],
          ),

          // Floating nav bar
          Positioned(
            left: _supportsLiquidGlass ? 12 : 0,
            right: _supportsLiquidGlass ? 12 : 0,
            bottom:
                isIOS
                    ? _supportsLiquidGlass
                        ? -MediaQuery.of(context).padding.bottom + 5
                        : -MediaQuery.of(context).padding.bottom
                    : 0,
            child: SafeArea(
              bottom: Platform.isIOS ? true : false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NewBottomNavBar(
                    onItemTapped: _onPageChangedByNavBar,
                    supportsLiquidGlass: _supportsLiquidGlass,
                  ),
                ],
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
