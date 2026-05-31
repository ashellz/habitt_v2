import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class LastWeekProgress extends StatefulWidget {
  const LastWeekProgress({super.key});

  @override
  State<LastWeekProgress> createState() => _LastWeekProgressState();
}

class _LastWeekProgressState extends State<LastWeekProgress>
    with AutomaticKeepAliveClientMixin<LastWeekProgress> {
  static const int _visibleDays = 7;
  static const int _maxPastDays = 30;
  static const double _dayWidth = 45;

  @override
  bool get wantKeepAlive => true;

  List<String> _days = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _progressValuesByDate = <String, double>{};
  final Map<String, double> _previousProgressValuesByDate = <String, double>{};
  Locale? _lastLocale;
  bool? _didInitialScrollToRight;
  bool _isAtRightEdge = true;
  late VoidCallback _habitProviderListener;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkLocale();
      _initializeAllProgressValues();
      _attachHabitProviderListener();
      _ensureInitialScrollPosition();
    });
  }

  void _attachHabitProviderListener() {
    final habitProvider = context.read<HabitProvider>();
    _habitProviderListener = () {
      if (!mounted) return;
      _updateChangedDayProgress();
    };
    habitProvider.addListener(_habitProviderListener);
  }

  Future<void> _initializeAllProgressValues() async {
    final habitProvider = context.read<HabitProvider>();
    final allDates = _allDates;

    if (allDates.isEmpty || !mounted) return;

    // Load only the visible 7 days immediately so the first frame renders fast
    final visibleStart = (allDates.length - _visibleDays).clamp(
      0,
      allDates.length,
    );
    setState(() {
      for (final date in allDates.sublist(visibleStart)) {
        final key = _dateKey(date);
        _progressValuesByDate[key] = _progressForDate(habitProvider, date);
        _previousProgressValuesByDate[key] = 0.0;
      }
    });

    // Load remaining past days in background micro-batches
    for (int i = 0; i < visibleStart; i += 7) {
      if (!mounted) return;
      await Future.microtask(() {});
      if (!mounted) return;
      final batchEnd = (i + 7).clamp(0, visibleStart);
      setState(() {
        for (final date in allDates.sublist(i, batchEnd)) {
          final key = _dateKey(date);
          if (!_progressValuesByDate.containsKey(key)) {
            _progressValuesByDate[key] = _progressForDate(habitProvider, date);
            _previousProgressValuesByDate[key] = 0.0;
          }
        }
      });
    }
  }

  void _updateChangedDayProgress() {
    final habitProvider = context.read<HabitProvider>();
    final today = _normalizeDate(DateTime.now());

    // Update progress for today
    final todayKey = _dateKey(today);
    final newTodayProgress = _progressForDate(habitProvider, today);
    final oldTodayProgress = _progressValuesByDate[todayKey] ?? 0.0;

    if ((newTodayProgress - oldTodayProgress).abs() > 0.0001) {
      setState(() {
        _previousProgressValuesByDate[todayKey] = oldTodayProgress;
        _progressValuesByDate[todayKey] = newTodayProgress;
      });
      return;
    }

    // If today didn't change, check the selected date
    final selectedDate = _normalizeDate(
      habitProvider.selectedDate ?? DateTime.now(),
    );

    if (_isSameDay(selectedDate, today)) return;

    final selectedKey = _dateKey(selectedDate);
    final newSelectedProgress = _progressForDate(habitProvider, selectedDate);
    final oldSelectedProgress = _progressValuesByDate[selectedKey] ?? 0.0;

    if ((newSelectedProgress - oldSelectedProgress).abs() > 0.0001) {
      setState(() {
        _previousProgressValuesByDate[selectedKey] = oldSelectedProgress;
        _progressValuesByDate[selectedKey] = newSelectedProgress;
      });
    }
  }

  void _checkLocale() {
    final locale = Localizations.localeOf(context);
    final l = AppLocalizations.of(context)!;

    final needsUpdate = _lastLocale != locale;
    if (!needsUpdate) return;

    final days = [l.mon, l.tue, l.wed, l.thu, l.fri, l.sat, l.sun];
    setState(() {
      _lastLocale = locale;
      _days = days;
    });
  }

  void _ensureInitialScrollPosition() {
    if (_didInitialScrollToRight == true || !_scrollController.hasClients) {
      return;
    }

    final habitProvider = context.read<HabitProvider>();
    final selectedDate = habitProvider.selectedDate;
    final allDates = _allDates;
    final today = _normalizeDate(DateTime.now());

    // Keep today's selection pinned to the latest day instead of centering it.
    if (selectedDate != null && _isSameDay(selectedDate, today)) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _didInitialScrollToRight = true;
      _updateRightEdgeState();
      return;
    }

    if (selectedDate != null) {
      final normalizedSelected = _normalizeDate(selectedDate);
      final selectedIndex = allDates.indexWhere(
        (d) => _isSameDay(d, normalizedSelected),
      );

      if (selectedIndex != -1) {
        final viewportWidth = _scrollController.position.viewportDimension;
        final spacing = ((viewportWidth - 32 - (_dayWidth * _visibleDays)) /
                (_visibleDays - 1))
            .clamp(0.0, 24.0);

        final itemStart = selectedIndex * (_dayWidth + spacing);
        final itemCenter = itemStart + (_dayWidth / 2);
        final targetOffset = (itemCenter - (viewportWidth / 2)).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

        _scrollController.jumpTo(targetOffset);
        _didInitialScrollToRight = true;
        _updateRightEdgeState();
        return;
      }
    }

    _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 32);
    _didInitialScrollToRight = true;
    _updateRightEdgeState();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    _updateRightEdgeState();
  }

  void _updateRightEdgeState() {
    if (!_scrollController.hasClients || !mounted) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    final atRightEdge = current >= (maxScroll - 0.5);

    if (atRightEdge == _isAtRightEdge) return;

    setState(() {
      _isAtRightEdge = atRightEdge;
    });
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    final f = _normalizeDate(first);
    final s = _normalizeDate(second);
    return f == s;
  }

  String _dateKey(DateTime date) {
    return _normalizeDate(date).toIso8601String().split('T').first;
  }

  List<DateTime> get _allDates {
    final today = _normalizeDate(DateTime.now());
    final oldest = today.subtract(Duration(days: _maxPastDays));
    final futureFillDays = (7 - today.weekday).clamp(0, 6);

    return List<DateTime>.generate(
      _maxPastDays + 1 + futureFillDays,
      (index) => oldest.add(Duration(days: index)),
      growable: false,
    );
  }

  String _dayLabel(DateTime date) {
    final index = date.weekday - 1;
    if (index < 0 || index >= _days.length) {
      return '';
    }
    return _days[index];
  }

  double _progressForDate(HabitProvider habitProvider, DateTime date) {
    final day = _normalizeDate(date);
    final today = _normalizeDate(DateTime.now());
    if (day.isAfter(today)) {
      return 0;
    }

    final weekProgress = habitProvider.getThisWeekProgress(anchorDate: day);
    return (weekProgress[day] ?? 0.0).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    try {
      final habitProvider = context.read<HabitProvider>();
      habitProvider.removeListener(_habitProviderListener);
    } catch (_) {
      // Provider not available, ignore
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _checkLocale();
    final habitProvider = context.read<HabitProvider>();
    final selectedDate = _normalizeDate(
      habitProvider.selectedDate ?? DateTime.now(),
    );

    final cp = context.watch<ColorProvider>();
    final darkMode = cp.isDark;
    final showRightArrowHint = !_isAtRightEdge;
    final rightFadeWidth = showRightArrowHint ? 96.0 : 32.0;

    return SizedBox(
      height: 79,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = ((constraints.maxWidth -
                      32 -
                      (_dayWidth * _visibleDays)) /
                  (_visibleDays - 1))
              .clamp(0.0, 24.0);

          final allDates = _allDates;
          final today = _normalizeDate(DateTime.now());

          return ClipRect(
            child: Stack(
              children: [
                ListView.separated(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: allDates.length,
                  separatorBuilder: (_, __) => SizedBox(width: spacing),
                  itemBuilder: (context, index) {
                    final startDate = context.read<HabitProvider>().dateJoined;
                    final date = allDates[index];
                    final dayKey = _dateKey(date);
                    final isSelected = _isSameDay(date, selectedDate);
                    final isSelectable =
                        !date.isAfter(today) && !date.isBefore(startDate);
                    final isToday = _isSameDay(date, today);

                    final progressValue =
                        _progressValuesByDate[dayKey]?.clamp(0.0, 1.0) ?? 0.0;
                    final previousValue =
                        _previousProgressValuesByDate[dayKey]?.clamp(
                          0.0,
                          1.0,
                        ) ??
                        0.0;

                    Color getBgColor() {
                      if (isSelected) {
                        return cp.pill;
                      }
                      if (isToday && !darkMode) {
                        return cp.border;
                      }
                      return Colors.transparent;
                    }

                    Color getWeekdayColor() {
                      if (isSelected && !darkMode) {
                        return Colors.white.withValues(alpha: 0.7);
                      }
                      if (isToday && darkMode) {
                        return Colors.white.withValues(alpha: 0.7);
                      }
                      return cp.greyText;
                    }

                    Color getBorderColor() {
                      if (isToday && darkMode && !isSelected) {
                        return cp.border;
                      }
                      return Colors.transparent;
                    }

                    Color getDayNumberColor() {
                      if (isSelected) {
                        if (darkMode) return Colors.white;
                        return cp.bg;
                      }
                      return cp.text;
                    }

                    Color progressColor() {
                      if (progressValue >= 0.5) return cp.main;
                      if (progressValue >= 0.3) return cp.mid;
                      if (progressValue < 0.3) return cp.fail;
                      return cp.disabled;
                    }

                    Color emptyProgressColor() {
                      if (isSelected) {
                        return cp.progressBarSelected;
                      }
                      if (isToday) {
                        return cp.disabled;
                      }
                      if (!isSelectable) {
                        if (darkMode) return Color(0xFF1A1A1A);
                        return Color(0xFFF1F1F1);
                      }
                      return cp.disabled;
                    }

                    final isAndroid =
                        Theme.of(context).platform == TargetPlatform.android;

                    final isLast = index == allDates.length - 1;

                    return Padding(
                      padding: EdgeInsets.only(right: isLast ? 16 : 0),
                      child: SizedBox(
                        width: _dayWidth,
                        child: ElevatedButton(
                          onPressed:
                              isSelectable
                                  ? () {
                                    context
                                        .read<HabitProvider>()
                                        .setSelectedDate(date);
                                  }
                                  : null,
                          style: ButtonStyle(
                            side: WidgetStatePropertyAll(
                              BorderSide(color: getBorderColor(), width: 1),
                            ),
                            minimumSize: const WidgetStatePropertyAll(
                              Size(45, 79),
                            ),
                            maximumSize: const WidgetStatePropertyAll(
                              Size(45, 79),
                            ),
                            fixedSize: const WidgetStatePropertyAll(
                              Size(45, 79),
                            ),
                            splashFactory:
                                isAndroid ? null : NoSplash.splashFactory,
                            elevation: const WidgetStatePropertyAll(0),
                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>((
                                  states,
                                ) {
                                  if (!states.contains(WidgetState.pressed)) {
                                    return null;
                                  }

                                  return cp.pill.withValues(alpha: 0.2);
                                }),

                            backgroundColor: WidgetStatePropertyAll(
                              getBgColor(),
                            ),
                            shadowColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            shape: const WidgetStatePropertyAll(
                              StadiumBorder(),
                            ),
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.zero,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Column(
                              children: [
                                Text(
                                  _dayLabel(date),
                                  style: TextStyle(
                                    color: getWeekdayColor(),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: getDayNumberColor(),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 15),
                                SizedBox(
                                  width: 27,
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey<String>(dayKey),
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
                                    curve: Curves.easeOut,
                                    tween: Tween<double>(
                                      begin: previousValue,
                                      end: progressValue,
                                    ),
                                    builder: (context, animatedProgress, _) {
                                      return CustomPaint(
                                        painter: PartialArcPainter(
                                          progress: animatedProgress,
                                          color: progressColor(),
                                          backgroundColor: emptyProgressColor(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap:
                      () => _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: double.infinity,
                      width: rightFadeWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [cp.bg, cp.habitBg.withValues(alpha: 0)],
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder:
                            (child, animation) => FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                        child:
                            showRightArrowHint
                                ? Align(
                                  key: const ValueKey(
                                    'right-arrow-hint-visible',
                                  ),
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: RotatedBox(
                                      quarterTurns: 2,
                                      child: SvgPicture.asset(
                                        "assets/images/new-svg/back.svg",
                                        colorFilter: ColorFilter.mode(
                                          cp.greyText,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                : const SizedBox(
                                  key: ValueKey('right-arrow-hint-hidden'),
                                ),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: double.infinity,
                      width: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [cp.bg, cp.habitBg.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PartialArcPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final double totalAngle; // in radians

  PartialArcPainter({
    required this.progress,
    this.strokeWidth = 3.5,
    required this.color,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.totalAngle = pi, // 180 degrees: left center to right center
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 3; // span full width for a half-arc

    // Start from center-left, sweep clockwise along the bottom to center-right.
    final startAngle = pi; // 180°
    final sweepAngle = totalAngle * progress;

    final bgPaint =
        Paint()
          ..color = backgroundColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square;

    final fgPaint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.square;

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    // Draw full background half-arc.
    canvas.drawArc(arcRect, startAngle, totalAngle, false, bgPaint);

    // Draw foreground progress over it.
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant PartialArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
