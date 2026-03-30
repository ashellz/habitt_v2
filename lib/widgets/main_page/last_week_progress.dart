import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

class LastWeekProgress extends StatefulWidget {
  const LastWeekProgress({super.key});

  @override
  State<LastWeekProgress> createState() => _LastWeekProgressState();
}

class _LastWeekProgressState extends State<LastWeekProgress> {
  static const int _visibleDays = 7;
  static const int _maxPastDays = 30;
  static const double _dayWidth = 45;

  List<String> _days = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _progressValuesByDate = <String, double>{};
  final Map<String, double> _previousProgressValuesByDate = <String, double>{};
  Locale? _lastLocale;
  bool _frameUpdateQueued = false;
  bool _didInitialScrollToRight = false;
  double _slotExtent = _dayWidth;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkLocale();
      _queueFrameUpdate(animateFromCurrent: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLocale();
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

  int _maxStartIndex() {
    return max(0, _allDates.length - _visibleDays);
  }

  int _visibleStartIndex() {
    if (!_scrollController.hasClients || _slotExtent <= 0) {
      return 0;
    }

    final start = (_scrollController.offset / _slotExtent).round();
    return start.clamp(0, _maxStartIndex());
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

  bool _didVisibleProgressChange(Map<String, double> nextValues) {
    for (final entry in nextValues.entries) {
      final currentValue = _progressValuesByDate[entry.key];
      if (currentValue == null) {
        return true;
      }
      if ((currentValue - entry.value).abs() > 0.0001) {
        return true;
      }
    }

    return false;
  }

  void _refreshVisibleProgress({required bool animateFromCurrent}) {
    final habitProvider = context.read<HabitProvider>();
    final start = _visibleStartIndex();
    final visibleDates = _allDates.skip(start).take(_visibleDays).toList();

    if (visibleDates.isEmpty) {
      return;
    }

    final nextValues = <String, double>{};
    for (final date in visibleDates) {
      final key = _dateKey(date);
      nextValues[key] = _progressForDate(habitProvider, date);
    }

    if (!_didVisibleProgressChange(nextValues)) {
      return;
    }

    setState(() {
      for (final entry in nextValues.entries) {
        final previous = _progressValuesByDate[entry.key] ?? 0.0;
        _previousProgressValuesByDate[entry.key] =
            animateFromCurrent ? previous : 0.0;
        _progressValuesByDate[entry.key] = entry.value;
      }

      debugPrint("Progress values updated: $nextValues");
      debugPrint("Days: $_days");
    });
  }

  void _handleScroll() {
    _queueFrameUpdate(animateFromCurrent: true);
  }

  void _ensureInitialScrollToRight() {
    if (_didInitialScrollToRight || !_scrollController.hasClients) {
      return;
    }

    _scrollController.jumpTo(_scrollController.position.maxScrollExtent + 32);
    _didInitialScrollToRight = true;
  }

  void _queueFrameUpdate({required bool animateFromCurrent}) {
    if (_frameUpdateQueued) return;
    _frameUpdateQueued = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameUpdateQueued = false;
      if (!mounted) return;
      _ensureInitialScrollToRight();
      _refreshVisibleProgress(animateFromCurrent: animateFromCurrent);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final selectedDate = _normalizeDate(
      habitProvider.selectedDate ?? DateTime.now(),
    );

    final cp = context.watch<ColorProvider>();
    final darkMode = cp.isDark;

    return SizedBox(
      height: 79,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = ((constraints.maxWidth -
                      32 -
                      (_dayWidth * _visibleDays)) /
                  (_visibleDays - 1))
              .clamp(0.0, 24.0);

          _slotExtent = _dayWidth + spacing;

          _queueFrameUpdate(animateFromCurrent: true);

          final allDates = _allDates;
          final today = _normalizeDate(DateTime.now());

          return ClipRect(
            child: ListView.separated(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: allDates.length,
              separatorBuilder: (_, __) => SizedBox(width: spacing),
              itemBuilder: (context, index) {
                final date = allDates[index];
                final dayKey = _dateKey(date);
                final isSelected = _isSameDay(date, selectedDate);
                final isSelectable = !date.isAfter(today);
                final isAfterToday = date.isAfter(today);

                final progressValue =
                    _progressValuesByDate[dayKey]?.clamp(0.0, 1.0) ?? 0.0;
                final previousValue =
                    _previousProgressValuesByDate[dayKey]?.clamp(0.0, 1.0) ??
                    0.0;

                Color getBgColor() {
                  if (isSelected) {
                    return cp.pill;
                  }
                  return Colors.transparent;
                }

                Color getWeekdayColor() {
                  if (isSelected) {
                    return Colors.white.withValues(alpha: 0.7);
                  }
                  return cp.greyText;
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
                  if (isAfterToday) {
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
                                context.read<HabitProvider>().setSelectedDate(
                                  date,
                                );
                              }
                              : null,
                      style: ButtonStyle(
                        minimumSize: const WidgetStatePropertyAll(Size(45, 79)),
                        maximumSize: const WidgetStatePropertyAll(Size(45, 79)),
                        fixedSize: const WidgetStatePropertyAll(Size(45, 79)),
                        splashFactory:
                            isAndroid ? null : NoSplash.splashFactory,
                        elevation: const WidgetStatePropertyAll(0),
                        overlayColor: WidgetStateProperty.resolveWith<Color?>((
                          states,
                        ) {
                          if (!states.contains(WidgetState.pressed)) {
                            return null;
                          }

                          return cp.pill.withValues(alpha: 0.2);
                        }),
                        backgroundColor: WidgetStatePropertyAll(getBgColor()),
                        shadowColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        shape: const WidgetStatePropertyAll(StadiumBorder()),
                        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
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
                                duration: const Duration(milliseconds: 1200),
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
