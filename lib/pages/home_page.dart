import 'package:flutter/material.dart';
import 'package:habitt/pages/main_pages/calendar_page.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/pages/main_pages/settings_page.dart';
import 'package:habitt/pages/main_pages/stats_page.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:habitt/widgets/default/bottom_nav_bar.dart';
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
    final isGlassFeel = context.watch<PreferencesProvider>().glassFeel;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final backupProvider = context.watch<BackupProvider>();
    final loading = backupProvider.syncState == SyncState.syncing;

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
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),

          // Floating nav bar
          Positioned(
            left: 0,
            right: 0,
            bottom: isIOS && isGlassFeel ? -20 : 0,
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
