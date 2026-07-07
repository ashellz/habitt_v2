import 'package:confetti/confetti.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/util/get_capitalized_first.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/util/insight_sheet_flow.dart';
import 'package:habitt/widgets/main_page/calendar_expansion_controller.dart';
import 'package:habitt/widgets/main_page/categories/new_categories_list.dart';
import 'package:habitt/widgets/main_page/habits/new_habits.dart';
import 'package:habitt/widgets/main_page/main_page_top_section.dart';
import 'package:habitt/widgets/main_page/month_progress_calendar.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

class MainPage extends StatefulWidget {
  const MainPage({
    super.key,
    required this.isActive,
    required this.lifecycleTick,
  });

  final bool isActive;
  final int lifecycleTick;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late final ConfettiController _confettiController;
  bool _wasAllCompleted = false;
  bool _initializedCompletionState = false;
  late VoidCallback _habitProviderListener;
  bool _hasHabitListener = false;
  final InsightSheetFlow _insightSheetFlow = InsightSheetFlow();
  late final AnimationController _calendarController;
  late final CalendarExpansionController _calendarExpansion;
  late final AnimationController _calendarHeightController;
  double _fromCalendarHeight = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _calendarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _calendarHeightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _calendarExpansion = CalendarExpansionController(
      animation: _calendarController,
      onDragUpdate: _handleCalendarDragUpdate,
      onDragEnd: _handleCalendarDragEnd,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _attachHabitProviderListener();
      _insightSheetFlow.scheduleInsightEvaluation(
        context,
        isActive: () => mounted && widget.isActive,
        immediate: true,
      );
    });
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final becameActive = !oldWidget.isActive && widget.isActive;
    final lifecycleChanged = oldWidget.lifecycleTick != widget.lifecycleTick;
    if (becameActive || (lifecycleChanged && widget.isActive)) {
      _insightSheetFlow.scheduleInsightEvaluation(
        context,
        isActive: () => mounted && widget.isActive,
        immediate: true,
      );
    }
  }

  @override
  void dispose() {
    _insightSheetFlow.dispose();
    if (_hasHabitListener) {
      try {
        context.read<HabitProvider>().removeListener(_habitProviderListener);
      } catch (_) {
        // Provider may not be available during teardown.
      }
    }
    _confettiController.dispose();
    _calendarController.dispose();
    _calendarHeightController.dispose();
    super.dispose();
  }

  // current displayed month on progress calendar
  DateTime? _focusedCalendarMonth;

  void _onCalendarMonthChanged(DateTime month) {
    if (!mounted || _focusedCalendarMonth == month) return;

    _fromCalendarHeight = _expandedCalendarHeight(context);
    setState(() {
      _focusedCalendarMonth = month;
    });
    _calendarHeightController.forward(from: 0);
  }

  double _rawCalendarHeightFor(DateTime month) {
    final topPadding = MediaQuery.of(context).padding.top;
    final weeks = MonthProgressCalendar.weeksInMonth(month);
    return topPadding +
        12 +
        MonthProgressCalendar.headerHeight +
        16 +
        MonthProgressCalendar.daysOfWeekHeight +
        weeks * MonthProgressCalendar.rowHeight +
        40;
  }

  double _expandedCalendarHeight(BuildContext context) {
    final month =
        _focusedCalendarMonth ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    final target = _rawCalendarHeightFor(month);
    if (!_calendarHeightController.isAnimating) {
      return target;
    }

    final t = _calendarHeightController.value;
    return _fromCalendarHeight + (target - _fromCalendarHeight) * t;
  }

  void _handleCalendarDragUpdate(double delta) {
    _calendarController.value += delta / _expandedCalendarHeight(context);
  }

  void _handleCalendarDragEnd(double velocity) {
    if (velocity > 300) {
      _calendarController.fling(velocity: 1);
    } else if (velocity < -300) {
      _calendarController.fling(velocity: -1);
    } else if (_calendarController.value > 0.5) {
      _calendarController.fling(velocity: 1);
    } else {
      _calendarController.fling(velocity: -1);
    }
  }

  void _collapseCalendar() {
    _calendarController.fling(velocity: -1);
  }

  void _onCalendarDaySelected(DateTime day) {
    context.read<HabitProvider>().setSelectedDate(day);
    _calendarExpansion.revealDay(day);
    _collapseCalendar();
  }

  Widget _calendarOverlay(ColorProvider cp) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _calendarController,
        _calendarHeightController,
      ]),
      builder: (context, child) {
        final t = _calendarController.value;
        if (t <= 0) {
          return const SizedBox.shrink();
        }
        final expandedHeight = _expandedCalendarHeight(context);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _collapseCalendar,
                child: ColoredBox(
                  color: cp.greyText.darken().withValues(alpha: 0.3 * t),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: expandedHeight * t,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                child: ColoredBox(
                  color: cp.bg,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: expandedHeight,
                        child: Opacity(
                          opacity: ((t - 0.3) / 0.7).clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: _calendarCardContent(cp),
    );
  }

  Widget _calendarCardContent(ColorProvider cp) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topPadding + 12, left: 16, right: 16),
      child: Column(
        children: [
          MonthProgressCalendar(
            onDaySelected: _onCalendarDaySelected,
            onMonthChanged: _onCalendarMonthChanged,
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate:
                  (details) => _handleCalendarDragUpdate(details.delta.dy),
              onVerticalDragEnd:
                  (details) => _handleCalendarDragEnd(
                    details.velocity.pixelsPerSecond.dy,
                  ),
              child: SizedBox(
                width: double.infinity,
                height: 16,
                child: Column(
                  children: [
                    Spacer(),
                    SvgPicture.asset('assets/images/new-svg/drag.svg'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _attachHabitProviderListener() {
    if (_hasHabitListener) {
      return;
    }

    final habitProvider = context.read<HabitProvider>();
    _habitProviderListener = () {
      if (!mounted || !widget.isActive) {
        return;
      }
      _insightSheetFlow.scheduleInsightEvaluation(
        context,
        isActive: () => mounted && widget.isActive,
      );
    };
    habitProvider.addListener(_habitProviderListener);
    _hasHabitListener = true;
  }

  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _selectedDayLabel(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final now = DateTime.now();

    final selectedDay = habitProvider.selectedDate ?? now;

    if (isToday(selectedDay)) {
      final loc = AppLocalizations.of(context)!;
      return loc.today;
    }

    final locale = Localizations.localeOf(context).toString();
    final formatted = DateFormat('EEE, d MMM', locale).format(selectedDay);
    final parts = formatted.split(', ');
    if (parts.length != 2) {
      return capitalizeFirst(formatted);
    }

    final dayPart = capitalizeFirst(parts[0]);
    final datePart = parts[1].split(' ').map(capitalizeFirst).join(' ');
    return '$dayPart, $datePart';
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const bottomNavBar = 95;

    final habits = habitProvider.todaysHabits;
    final requiredHabits = habits.where((habit) => !habit.optional);

    final bool allCompleted =
        requiredHabits.isNotEmpty &&
        requiredHabits.every((habit) => habit.completed);
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

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 2, child: Container(color: cp.bg)),
              Expanded(child: Container(color: cp.habitBg)),
            ],
          ),
          ListView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            physics: const ClampingScrollPhysics(),
            children: [
              MainPageTopSection(expansionController: _calendarExpansion),
              Container(
                color: cp.habitBg,
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return SizeTransition(
                          sizeFactor: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(habitProvider.selectedDate),
                        child:
                            isToday(
                                  habitProvider.selectedDate ?? DateTime.now(),
                                )
                                ? SizedBox.shrink()
                                : Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _selectedDayLabel(context),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color:
                                              cp.isDark
                                                  ? cp.lightGreyText
                                                  : cp.greyText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    if (context
                        .watch<PreferencesProvider>()
                        .showCategoriesOnMainPage)
                      NewCategoriesList(),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                      ),
                      child: NewHabits(),
                    ),
                    SizedBox(height: bottomPadding + bottomNavBar),
                  ],
                ),
              ),
            ],
          ),

          _calendarOverlay(cp),

          // Confetti celebration when all habits are completed
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                minimumSize: const Size(10, 5),
                maximumSize: const Size(20, 10),
                emissionFrequency: 0.08,
                numberOfParticles: 24,
                maxBlastForce: 20,
                minBlastForce: 5,
                gravity: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
