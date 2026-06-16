import 'dart:io';
import 'package:flutter/material.dart';
import 'package:habitt/pages/main_pages/calendar_page.dart';
import 'package:habitt/pages/main_pages/habits_page.dart';
import 'package:habitt/pages/main_pages/main_page.dart';
import 'package:habitt/pages/main_pages/profile_page.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/status_overlay_popup.dart';
import 'package:habitt/util/supports_liquid_glass.dart';
import 'package:habitt/util/sync_progress_overlay.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:habitt/widgets/default/new_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentPageIndex = 0;
  int _lifecycleTick = 0;
  bool _supportsLiquidGlass = false;
  late final StatusOverlayPopupController _statusPopup;
  VoidCallback? _backupListener;

  // Check if app state has changed, therefore run _updateLastOpenedDate
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final categoryProvider = context.read<CategoryProvider>();

    if (state == AppLifecycleState.paused) {
      context.read<BackupProvider>().flushPendingSyncIfNeeded();
    }

    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final backupProvider = context.read<BackupProvider>();
        // Update last opened date, reset habit completion
        await updateLastOpenedDate(
          context.read<HabitProvider>(),
          context.read<StateProvider>(),
          context.read<StatsProvider>(),
        );
        categoryProvider.reorderCategoriesBasedOnTime();

        // If the app was only briefly backgrounded, we skip the full Drive check
        // (which looks for newer full backups and all remote deltas). Just
        // flush any pending local upload instead. The periodic timer and the
        // next stale resume will catch compaction / new deltas within 30s–2min.
        if (backupProvider.isSyncStale) {
          await backupProvider.performSync();
        } else {
          await backupProvider.performSync(false, SyncMode.uploadOnly);
        }
        if (!mounted) {
          return;
        }
        context.read<StatsProvider>().addShouldRefresh(
          StatsType.perfectDaysStreak,
        );
        setState(() {
          _lifecycleTick += 1;
        });
      });
    }
  }

  // Do the same thing on initialization
  @override
  void initState() {
    super.initState();

    _statusPopup = StatusOverlayPopupController(vsync: this);

    _checkLiquidGlassSupport();

    // Set default to home page (index 0)
    _currentPageIndex = 0;

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final backupProvider = context.read<BackupProvider>();

      // Show popup for any notification queued before the widget mounted
      // (e.g. Drive scope revoked during initialize()).
      _maybeShowBackupNotification(backupProvider);

      _backupListener = () {
        if (!mounted) return;
        _maybeShowBackupNotification(context.read<BackupProvider>());
        _maybeShowSyncOverlay();
      };
      backupProvider.addListener(_backupListener!);

      final stateProvider = context.read<StateProvider>();
      final statsProvider = context.read<StatsProvider>();

      await updateLastOpenedDate(
        context.read<HabitProvider>(),
        stateProvider,
        statsProvider,
      );
      await backupProvider.initializationDone;
      await backupProvider.performSync();

      if (mounted) {
        statsProvider.addShouldRefresh(StatsType.perfectDaysStreak);
      }

      if (stateProvider.shouldUpdateStreaks && mounted) {
        context.read<HabitProvider>().assignStreaks();
        stateProvider.shouldUpdateStreaks = false;
      }

      if (!mounted) return;
      setState(() {
        _lifecycleTick += 1;
      });
    });
  }

  void _maybeShowSyncOverlay() {
    if (!mounted) return;
    final bp = context.read<BackupProvider>();
    if (bp.syncState != SyncState.syncing) return;
    final hasIncomingWork = bp.syncTotalDeltas > 0 || bp.syncHasBackup;
    final showUpload =
        bp.syncIsUploading &&
        context.read<PreferencesProvider>().showUploadActivity;
    if (hasIncomingWork || showUpload) {
      SyncProgressOverlay.showIfNeeded(
        context,
        bp,
        context.read<ColorProvider>(),
      );
    }
  }

  void _maybeShowBackupNotification(BackupProvider backupProvider) {
    final message = backupProvider.pendingNotification;
    if (message == null) return;
    backupProvider.clearPendingNotification();
    _statusPopup.show(
      context: context,
      cp: context.read<ColorProvider>(),
      title: message,
      isError: true,
    );
  }

  @override
  void dispose() {
    if (_backupListener != null) {
      try {
        context.read<BackupProvider>().removeListener(_backupListener!);
      } catch (_) {}
    }
    _statusPopup.dispose();
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

    final pages = [
      MainPage(isActive: _currentPageIndex == 0, lifecycleTick: _lifecycleTick),
      const HabitsPage(),
      CalendarPage(isActive: _currentPageIndex == 2),
      const ProfilePage(),
    ];

    return Scaffold(
      body: Stack(
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
                  children: pages,
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
