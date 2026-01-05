import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:habitt/pages/main_pages/daily_plan_page.dart';
import 'package:habitt/pages/other_pages/add_habit_page.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/default/alert_popup.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:habitt/widgets/habits_page/habits.dart';
import 'package:habitt/widgets/habits_page/habits_completed/habits_completed_widget.dart';
import 'package:provider/provider.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listViewKey = GlobalKey();

  late final ConfettiController _confettiController;
  bool _wasAllCompleted = false;
  bool _initializedCompletionState = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Get initial geometry after the first frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateListViewportGeom(),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  // ====================================
  // Configuration for the stacking effect
  // ====================================

  // Pixels from bottom of viewport where effect starts
  final double _effectZoneHeight = 120.0;

  // Smallest scale for a stacked item
  final double _minScale = 0.85;

  // Factor of item height for upward offset (e.g., 0.15 = 15% of its height)
  final double _stackOffsetFactor = 0.15;

  double _bottomViewportEdgeGlobalY = 0;

  void _updateListViewportGeom() {
    if (!mounted || !_scrollController.hasClients) {
      // If not mounted or scroll controller not ready, try again after next frame
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _updateListViewportGeom(),
        );
      }
      return;
    }

    final RenderBox? listViewRenderBox =
        _listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (listViewRenderBox != null && listViewRenderBox.hasSize) {
      final listViewGlobalOffset = listViewRenderBox.localToGlobal(Offset.zero);
      final currentBottomViewportY =
          listViewGlobalOffset.dy +
          _scrollController.position.viewportDimension;

      // Only update state if the value actually changes to avoid unnecessary rebuilds
      if (_bottomViewportEdgeGlobalY != currentBottomViewportY) {
        setState(() {
          _bottomViewportEdgeGlobalY = currentBottomViewportY;
        });
      }
    } else {
      // If renderbox not available yet, retry
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updateListViewportGeom(),
      );
    }
  }

  void _onScroll() {
    // On scroll we use to update state and widgets after
    // every scroll which is necessary to do

    if (!mounted) return;
    // We need to call _updateListViewportGeom in case the listview's position/size changes
    // for example, due to keyboard or other dynamic UI elements above it.
    // However, for pure scrolling, its global Y and viewportDimension are often stable.
    // The primary need for setState is to make children re-evaluate their position.
    // _updateListViewportGeom(); // Call if you suspect ListView geometry changes during scroll
    setState(() {
      // This will cause visible HabitWidgets to rebuild and update their transforms
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final stateProvider = context.watch<StateProvider>();
    final habits = context.watch<HabitProvider>().habits;

    final bool allCompleted =
        habits.isNotEmpty && habits.every((habit) => habit.completed);
    if (!_initializedCompletionState) {
      _wasAllCompleted = allCompleted;
      _initializedCompletionState = true;
    } else {
      if (allCompleted && !_wasAllCompleted) {
        _confettiController.play();
      } else if (!allCompleted && _wasAllCompleted) {
        _confettiController.stop();
      }
      _wasAllCompleted = allCompleted;
    }

    if (stateProvider.showAlert) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          stateProvider.toggleAlert(show: false);
        }
      });
    }

    // Ensure viewport geometry is updated if screen size changes (e.g. orientation)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateListViewportGeom(),
    );

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        extendBody: true,
        body: Stack(
          children: [
            GradientBackground(
              child: ListView(
                key: _listViewKey,
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FloatingActionButton(
                              heroTag: 'habits-date-fab',
                              mini: true,
                              elevation: 0,
                              backgroundColor: tp.secondaryColor,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const DailyPlanPage(),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.date_range,
                                color: Colors.white,
                              ),
                            ),
                            FloatingActionButton(
                              heroTag: 'habits-add-fab',
                              mini: true,
                              elevation: 0,
                              backgroundColor: tp.primaryColor,
                              onPressed:
                                  () => Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) => AddHabitPage(),
                                        ),
                                      )
                                      .whenComplete(() {
                                        if (!context.mounted) return;
                                        final stateProvider =
                                            context.read<StateProvider>();
                                        stateProvider.reset();
                                      }),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Greeting(),
                        ),

                        const CategoriesList(),
                        const HabitsCompletedWidget(),
                      ],
                    ),
                  ),

                  // Pass down the necessary parameters for the effect
                  Habits(
                    scrollController: _scrollController,
                    bottomViewportEdgeGlobalY: _bottomViewportEdgeGlobalY,
                    effectZoneHeight: _effectZoneHeight,
                    minScale: _minScale,
                    stackOffsetFactor: _stackOffsetFactor,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Confetti celebration when all habits are completed
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.08,
                  numberOfParticles: 24,
                  maxBlastForce: 20,
                  minBlastForce: 5,
                  gravity: 0.6,
                  colors: [
                    tp.primaryColor,
                    tp.secondaryColor,
                    tp.successColor,
                    tp.dangerColor,
                  ],
                ),
              ),
            ),
            // Popup overlay
            AlertPopup(
              message: stateProvider.alertText,
              show: stateProvider.showAlert,
            ),
          ],
        ),
      ),
    );
  }
}
