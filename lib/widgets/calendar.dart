import 'package:flutter/material.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:inner_glow/inner_glow.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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
      child: CalendarContainer(
        child: TableCalendar(
          onDaySelected: calendarProvider.onDaySelected,
          availableGestures: AvailableGestures.horizontalSwipe,
          firstDay: DateTime.utc(2025, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: focusedDay,
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

class CalendarContainer extends StatefulWidget {
  const CalendarContainer({super.key, required this.child});

  final Widget child;

  @override
  State<CalendarContainer> createState() => _CalendarContainerState();
}

class _CalendarContainerState extends State<CalendarContainer> {
  final GlobalKey _containerKey = GlobalKey();
  double _height = 0;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame to get the size
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());
  }

  void _updateHeight() {
    final context = _containerKey.currentContext;
    if (context != null) {
      final newHeight = context.size?.height ?? 0;
      if (newHeight != _height) {
        setState(() {
          _height = newHeight;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();

    return Stack(
      children: [
        Container(
          key: _containerKey,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),

            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(colorProvider.isDarkMode ? 0.4 : 1),
                Colors.white.withOpacity(colorProvider.isDarkMode ? 0.05 : 0.2),
                Colors.white.withOpacity(colorProvider.isDarkMode ? 0.2 : 0.7),
              ],
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 13,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(1.5),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  colorProvider.colorScheme.standardColor,
                  colorProvider.habitColor,
                ],
              ),
              borderRadius: BorderRadius.circular(22.5),
            ),
            child: widget.child,
          ),
        ),

        IgnorePointer(
          child: InnerGlow(
            width: double.infinity,
            height: _height,
            thickness: colorProvider.isDarkMode ? 1 : 10,
            glowBlur: 15,
            glowRadius: 25,
            baseDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }
}
