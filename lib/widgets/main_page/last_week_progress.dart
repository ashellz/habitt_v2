import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/util/past_day_hint.dart';
import 'package:habitt/widgets/default/past_day_hint_dot.dart';
import 'package:habitt/widgets/main_page/calendar_expansion_controller.dart';
import 'package:habitt/widgets/main_page/downward_drag_gesture_recognizer.dart';
import 'package:provider/provider.dart';

class LastWeekProgress extends StatefulWidget {
  const LastWeekProgress({super.key, this.expansionController});
  final CalendarExpansionController? expansionController;

  @override
  State<LastWeekProgress> createState() => _LastWeekProgressState();
}

class _LastWeekProgressState extends State<LastWeekProgress>
    with AutomaticKeepAliveClientMixin<LastWeekProgress> {
  static const int _visibleDays = 7;
  static const int _initialPastDays = 30;
  static const int _chunkDays = 15;
  static const int _backfillTriggerDays = 7;
  static const int _backfillBufferDays = 7;
  static const double _dayWidth = 45;

  @override
  bool get wantKeepAlive => true;

  List<String> _days = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _previousProgressValuesByDate = <String, double>{};
  Locale? _lastLocale;
  bool _didInitialScroll = false;
  bool _isAtRightEdge = true;
  late VoidCallback _habitProviderListener;
  int _lastDataVersion = -1;
  int _pastDaysLoaded = _initialPastDays;
  bool _isLoadingChunk = false;
  double _lastSpacing = 24;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    widget.expansionController?.attachRevealDay(_revealDay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkLocale();
      _primeProgressValues(_allDates);
      _attachHabitProviderListener();
      _ensureInitialScrollPosition();
    });
  }

  @override
  void didUpdateWidget(covariant LastWeekProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expansionController != widget.expansionController) {
      oldWidget.expansionController?.detachRevealDay(_revealDay);
      widget.expansionController?.attachRevealDay(_revealDay);
    }
  }

  void _attachHabitProviderListener() {
    final habitProvider = context.read<HabitProvider>();
    _lastDataVersion = habitProvider.dataVersion;
    _habitProviderListener = () {
      if (!mounted) return;
      final provider = context.read<HabitProvider>();
      if (provider.dataVersion != _lastDataVersion) {
        _lastDataVersion = provider.dataVersion;
        _previousProgressValuesByDate.clear();
        // The shared cache self-clears on version change; recompute the range.
        _primeProgressValues(_allDates);
      } else {
        _updateChangedDayProgress();
      }
    };
    habitProvider.addListener(_habitProviderListener);
  }

  /// Fills the shared provider cache for [dates]. The first week is computed
  /// synchronously so the next frame paints real values; the rest loads in
  /// background micro-batches.
  Future<void> _primeProgressValues(List<DateTime> dates) async {
    if (dates.isEmpty || !mounted) return;
    final habitProvider = context.read<HabitProvider>();

    final firstEnd = _visibleDays.clamp(0, dates.length);
    setState(() {
      habitProvider.primeDayProgress(dates.sublist(0, firstEnd));
    });

    for (int i = firstEnd; i < dates.length; i += 7) {
      if (!mounted) return;
      await Future.microtask(() {});
      if (!mounted) return;
      final batchEnd = (i + 7).clamp(0, dates.length);
      setState(() {
        habitProvider.primeDayProgress(dates.sublist(i, batchEnd));
      });
    }
  }

  void _updateChangedDayProgress() {
    final habitProvider = context.read<HabitProvider>();
    final today = _normalizeDate(DateTime.now());

    final todayKey = _dateKey(today);
    final oldTodayProgress = habitProvider.cachedDayProgress(today) ?? 0.0;
    final newTodayProgress = habitProvider.refreshDayProgress(today);

    if ((newTodayProgress - oldTodayProgress).abs() > 0.0001) {
      setState(() {
        _previousProgressValuesByDate[todayKey] = oldTodayProgress;
      });
      return;
    }

    // if not today check selected date

    final selectedDate = _normalizeDate(
      habitProvider.selectedDate ?? DateTime.now(),
    );

    if (_isSameDay(selectedDate, today)) return;

    final selectedKey = _dateKey(selectedDate);
    final oldSelectedProgress =
        habitProvider.cachedDayProgress(selectedDate) ?? 0.0;
    final newSelectedProgress = habitProvider.refreshDayProgress(selectedDate);

    if ((newSelectedProgress - oldSelectedProgress).abs() > 0.0001) {
      setState(() {
        _previousProgressValuesByDate[selectedKey] = oldSelectedProgress;
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
    if (_didInitialScroll || !_scrollController.hasClients) {
      return;
    }
    _didInitialScroll = true;

    final habitProvider = context.read<HabitProvider>();
    final selectedDate = habitProvider.selectedDate;
    final today = _normalizeDate(DateTime.now());

    if (selectedDate == null || _isSameDay(selectedDate, today)) {
      _maybeScrollForPastDayHint();
      _updateRightEdgeState();
      return;
    }

    _scrollToDate(_normalizeDate(selectedDate), animate: false);
  }

  void _scrollToDate(DateTime date, {required bool animate}) {
    if (!_scrollController.hasClients) return;
    final index = _allDates.indexWhere((d) => _isSameDay(d, date));
    if (index == -1) return;

    final viewportWidth = _scrollController.position.viewportDimension;
    final itemCenter = index * (_dayWidth + _lastSpacing) + (_dayWidth / 2);
    final targetOffset = (itemCenter - (viewportWidth / 2)).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
    _updateRightEdgeState();
  }

  // loads more days to until selected day is reached, also loads 15 days before it
  // scrolls to center
  Future<void> _revealDay(DateTime day) async {
    if (!mounted) return;
    final today = _normalizeDate(DateTime.now());
    final target = _normalizeDate(day);
    final daysBack = today.difference(target).inDays;
    if (daysBack < 0) return;

    if (daysBack > _pastDaysLoaded) {
      final previousLength = _allDates.length;
      setState(() {
        _pastDaysLoaded = (daysBack + _backfillBufferDays).clamp(
          0,
          _maxPastDays,
        );
      });
      // first load the new days then scroll later
      await _primeProgressValues(_allDates.sublist(previousLength));
      if (!mounted) return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToDate(target, animate: true);
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    _updateRightEdgeState();
    _maybeLoadMorePastDays();
  }

  void _updateRightEdgeState() {
    if (!_scrollController.hasClients || !mounted) return;

    final atRightEdge = _scrollController.offset <= 0.5;

    if (atRightEdge == _isAtRightEdge) return;

    setState(() {
      _isAtRightEdge = atRightEdge;
    });
  }

  void _maybeLoadMorePastDays() {
    if (_isLoadingChunk || !_scrollController.hasClients || !mounted) return;

    final position = _scrollController.position;
    final remaining = position.maxScrollExtent - position.pixels;
    final threshold = _backfillTriggerDays * (_dayWidth + _lastSpacing);
    if (remaining > threshold) return;
    if (_pastDaysLoaded >= _maxPastDays) return;

    _isLoadingChunk = true;
    final previousLength = _allDates.length;
    setState(() {
      _pastDaysLoaded = (_pastDaysLoaded + _chunkDays).clamp(0, _maxPastDays);
    });
    _primeProgressValues(_allDates.sublist(previousLength)).whenComplete(() {
      _isLoadingChunk = false;
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

  int get _futureFillDays {
    final today = _normalizeDate(DateTime.now());
    return (7 - today.weekday).clamp(0, 6);
  }

  // max number of days based on dateJoined and today
  // used when loading more days to prevent loading too far back
  int get _maxPastDays {
    final habitProvider = context.read<HabitProvider>();
    final today = _normalizeDate(DateTime.now());
    final joined = _normalizeDate(habitProvider.dateJoined);
    final sinceJoined = today.difference(joined).inDays;
    return max(sinceJoined, _initialPastDays);
  }

  List<DateTime> get _allDates {
    final today = _normalizeDate(DateTime.now());
    final fill = _futureFillDays;

    return List<DateTime>.generate(
      _pastDaysLoaded + 1 + fill,
      (index) => DateTime(today.year, today.month, today.day + fill - index),
      growable: false,
    );
  }

  void _maybeScrollForPastDayHint() {
    if (!mounted || !_scrollController.hasClients) return;
    final habitProvider = context.read<HabitProvider>();
    final preferencesProvider = context.read<PreferencesProvider>();
    final eligible = isPastDayHintEligible(
      dateJoined: habitProvider.dateJoined,
      hasSelectedPastDay: preferencesProvider.hasSelectedPastDay,
    );
    if (!eligible) return;

    final today = _normalizeDate(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final index = _allDates.indexWhere((d) => _isSameDay(d, yesterday));
    if (index == -1 || index < _visibleDays) return;

    _scrollController.jumpTo(_dayWidth + _lastSpacing);
    _updateRightEdgeState();
  }

  String _dayLabel(DateTime date) {
    final index = date.weekday - 1;
    if (index < 0 || index >= _days.length) {
      return '';
    }
    return _days[index];
  }

  @override
  void dispose() {
    widget.expansionController?.detachRevealDay(_revealDay);
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
    final preferencesProvider = context.watch<PreferencesProvider>();
    final darkMode = cp.isDark;
    final showRightArrowHint = !_isAtRightEdge;
    final rightFadeWidth = showRightArrowHint ? 96.0 : 32.0;
    final pastDayHintEligible = isPastDayHintEligible(
      dateJoined: habitProvider.dateJoined,
      hasSelectedPastDay: preferencesProvider.hasSelectedPastDay,
    );
    final yesterday = _normalizeDate(
      DateTime.now(),
    ).subtract(const Duration(days: 1));

    final strip = SizedBox(
      height: 79,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = ((constraints.maxWidth -
                      32 -
                      (_dayWidth * _visibleDays)) /
                  (_visibleDays - 1))
              .clamp(0.0, 24.0);
          _lastSpacing = spacing;

          final allDates = _allDates;
          final today = _normalizeDate(DateTime.now());

          return ClipRect(
            child: Stack(
              children: [
                ListView.separated(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  reverse: true,
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
                        habitProvider
                            .cachedDayProgress(date)
                            ?.clamp(0.0, 1.0) ??
                        0.0;
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

                    // index 0 is the newest day, reversed list
                    final isNewest = index == 0;
                    final isOldest = index == allDates.length - 1;
                    final showHintDot =
                        pastDayHintEligible && _isSameDay(date, yesterday);

                    return Padding(
                      padding: EdgeInsets.only(
                        left: isOldest ? 16 : 0,
                        right: isNewest ? 16 : 0,
                      ),
                      child: SizedBox(
                        width: _dayWidth,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ElevatedButton(
                              onPressed:
                                  isSelectable
                                      ? () {
                                        if (!isToday) {
                                          context
                                              .read<PreferencesProvider>()
                                              .setHasSelectedPastDay(true);
                                        }
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
                                overlayColor: WidgetStateProperty.resolveWith<
                                  Color?
                                >((states) {
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 9,
                                ),
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
                                        builder: (
                                          context,
                                          animatedProgress,
                                          _,
                                        ) {
                                          return CustomPaint(
                                            painter: PartialArcPainter(
                                              progress: animatedProgress,
                                              color: progressColor(),
                                              backgroundColor:
                                                  emptyProgressColor(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (showHintDot)
                              const Positioned(
                                top: 2,
                                right: 2,
                                child: PastDayHintDot(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap:
                      () => _scrollController.animateTo(
                        0.0,
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

    final expansionController = widget.expansionController;
    if (expansionController == null) {
      return strip;
    }

    // downward drag using custom gesture recognizer

    return AnimatedBuilder(
      animation: expansionController.animation,
      builder: (context, child) {
        final t = expansionController.animation.value;
        return Opacity(opacity: (1 - t / 0.3).clamp(0.0, 1.0), child: child);
      },
      child: RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: <Type, GestureRecognizerFactory>{
          DownwardDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            DownwardDragGestureRecognizer
          >(() => DownwardDragGestureRecognizer(debugOwner: this), (
            recognizer,
          ) {
            recognizer.onUpdate =
                (details) => expansionController.onDragUpdate(details.delta.dy);
            recognizer.onEnd =
                (details) => expansionController.onDragEnd(
                  details.velocity.pixelsPerSecond.dy,
                );
            recognizer.onCancel = () => expansionController.onDragEnd(0);
          }),
        },
        child: strip,
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
