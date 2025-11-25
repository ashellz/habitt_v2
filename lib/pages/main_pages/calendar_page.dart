import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/calendar.dart';
import 'package:habitt/widgets/default_annotated_region.dart';
import 'package:habitt/widgets/default_cupertino_button.dart';
import 'package:habitt/widgets/gradient_background.dart';
import 'package:habitt/widgets/habits_page/habits.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listViewKey = GlobalKey();

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calendarProvider = context.read<CalendarProvider>();
      calendarProvider.resetFocusedDay();
    });

    _scrollController.addListener(_onScroll);
    // Get initial geometry after the first frame
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateListViewportGeom(),
    );
  }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure viewport geometry is updated if screen size changes (e.g. orientation)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateListViewportGeom(),
    );

    final tp = context.watch<ThemeProvider>();
    final calendarProvider = context.watch<CalendarProvider>();
    final stateProvider = context.watch<StateProvider>();

    final canEdit = stateProvider.canEditCalendar;
    final focusedDay = calendarProvider.focusedDay;

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: GradientBackground(
          child: _calendarPage(
            tp,
            calendarProvider,
            focusedDay,
            canEdit,
            stateProvider,
          ),
        ),
      ),
    );
  }

  ListView _calendarPage(
    ThemeProvider tp,
    CalendarProvider calendarProvider,
    DateTime focusedDay,
    bool canEdit,
    StateProvider stateProvider,
  ) {
    return ListView(
      key: _listViewKey,
      controller: _scrollController,
      children: [
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          "Calendar",
                          style: TextStyle(
                            fontSize: 38,
                            color: tp.primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0.3, 0), // from right to left
                            end: Offset.zero,
                          ).animate(animation);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child:
                            canEdit
                                ? Padding(
                                  key: const ValueKey('cancel'),
                                  padding: const EdgeInsets.only(right: 8),
                                  child: DefaultCupertinoButton(
                                    textColor: tp.backgroundColor,
                                    color: tp.primaryTextColor,
                                    onPressed:
                                        () =>
                                            stateProvider.canEditCalendar =
                                                false,
                                    text: "Cancel",
                                  ),
                                )
                                : const SizedBox.shrink(key: ValueKey('empty')),
                      ),
                      DefaultCupertinoButton(
                        textColor: Colors.white,
                        onPressed: () {
                          stateProvider.canEditCalendar = !canEdit;

                          if (canEdit) {
                            context.read<HabitProvider>().assignStreaks();
                          }
                        },
                        text: canEdit ? "Save" : "Edit",
                      ),
                    ],
                  ),
                ],
              ),
              Calendar(
                tp: tp,
                calendarProvider: calendarProvider,
                focusedDay: focusedDay,
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        IgnorePointer(
          ignoring: !canEdit,
          child: Habits(
            daySelected: focusedDay,
            hasMainCategory: false,
            scrollController: _scrollController,
            bottomViewportEdgeGlobalY: _bottomViewportEdgeGlobalY,
            effectZoneHeight: _effectZoneHeight,
            minScale: _minScale,
            stackOffsetFactor: _stackOffsetFactor,
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
