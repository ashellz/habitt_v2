import 'package:flutter/material.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habits_page/habits.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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

    final colorProvider = context.watch<ColorProvider>();
    final calendarProvider = context.watch<CalendarProvider>();

    final focusedDay = calendarProvider.focusedDay;

    return Scaffold(
      backgroundColor: colorProvider.backgroundColor,
      body: ListView(
        key: _listViewKey,
        controller: _scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Calendar",
                  style: TextStyle(
                    fontSize: 38,
                    color: colorProvider.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Calendar(
                  colorProvider: colorProvider,
                  calendarProvider: calendarProvider,
                  focusedDay: focusedDay,
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Habits(
            hasMainCategory: false,
            scrollController: _scrollController,
            bottomViewportEdgeGlobalY: _bottomViewportEdgeGlobalY,
            effectZoneHeight: _effectZoneHeight,
            minScale: _minScale,
            stackOffsetFactor: _stackOffsetFactor,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class Calendar extends StatelessWidget {
  const Calendar({
    super.key,
    required this.colorProvider,
    required this.calendarProvider,
    required this.focusedDay,
  });

  final ColorProvider colorProvider;
  final CalendarProvider calendarProvider;
  final DateTime focusedDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorProvider.standardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TableCalendar(
          onDaySelected: calendarProvider.onDaySelected,
          availableGestures: AvailableGestures.horizontalSwipe,
          firstDay: DateTime.utc(2025, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: DateTime.now(),
          selectedDayPredicate: (day) => isSameDay(day, focusedDay),
          // calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: HeaderStyle(
            titleTextStyle: TextStyle(
              color: colorProvider.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            formatButtonVisible: false,
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: colorProvider.textColor,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: colorProvider.textColor,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            dowTextFormatter: (date, locale) {
              return DateFormat.E(locale).format(date).toUpperCase();
            },
            weekendStyle: TextStyle(
              color: colorProvider.textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            weekdayStyle: TextStyle(
              color: colorProvider.textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: colorProvider.colorScheme.strokeColor,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: colorProvider.colorScheme.darkerStandardColor,
              shape: BoxShape.circle,
            ),
            outsideDaysVisible: false,

            defaultTextStyle: TextStyle(color: colorProvider.textColor),
            weekendTextStyle: TextStyle(color: colorProvider.textColor),
          ),
        ),
      ),
    );
  }
}
