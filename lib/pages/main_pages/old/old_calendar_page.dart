import 'package:flutter/material.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/widgets/calendar/calendar.dart';
import 'package:habitt/widgets/default/default_annotated_region.dart';
import 'package:habitt/widgets/default/gradient_background.dart';
import 'package:habitt/widgets/habits_page/categories/categories_list.dart';
import 'package:habitt/widgets/habits_page/habits.dart';
import 'package:provider/provider.dart';

class OldCalendarPage extends StatefulWidget {
  const OldCalendarPage({super.key});

  @override
  State<OldCalendarPage> createState() => _OldCalendarPageState();
}

class _OldCalendarPageState extends State<OldCalendarPage> {
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

    final focusedDay = calendarProvider.focusedDay;

    return DefaultAnnotatedRegion(
      child: Scaffold(
        backgroundColor: tp.backgroundColor,
        body: GradientBackground(
          child: _calendarPage(tp, calendarProvider, focusedDay, stateProvider),
        ),
      ),
    );
  }

  ListView _calendarPage(
    ThemeProvider tp,
    CalendarProvider calendarProvider,
    DateTime focusedDay,
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
              Padding(
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
              Calendar(
                tp: tp,
                calendarProvider: calendarProvider,
                focusedDay: focusedDay,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CategoriesList(selectedDay: focusedDay),
        ),
        Habits(
          daySelected: focusedDay,
          hasMainCategory: false,
          scrollController: _scrollController,
          bottomViewportEdgeGlobalY: _bottomViewportEdgeGlobalY,
          effectZoneHeight: _effectZoneHeight,
          minScale: _minScale,
          stackOffsetFactor: _stackOffsetFactor,
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
