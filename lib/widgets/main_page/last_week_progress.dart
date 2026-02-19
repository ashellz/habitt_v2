import 'dart:math';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';

class LastWeekProgress extends StatefulWidget {
  const LastWeekProgress({super.key});

  @override
  State<LastWeekProgress> createState() => _LastWeekProgressState();
}

class _LastWeekProgressState extends State<LastWeekProgress> {
  int currentDay = DateTime.now().weekday;
  List<String> _days = const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final List<double> _progressValues = List<double>.filled(
    7,
    0.0,
    growable: true,
  );
  final List<double> _previousProgressValues = List<double>.filled(
    7,
    0.0,
    growable: true,
  );
  Locale? _lastLocale;

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing _LastWeekProgress with currentDay: $currentDay");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocale();
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final Map<DateTime, double> progress =
          habitProvider.getThisWeekProgress();

      // Progress is filled with all the valeus all the time

      setState(() {
        final values = progress.values.take(7).toList();
        if (values.length < 7) {
          values.addAll(List.filled(7 - values.length, 0.0));
        }

        _progressValues
          ..clear()
          ..addAll(values);

        _previousProgressValues
          ..clear()
          ..addAll(List<double>.filled(7, 0.0));

        debugPrint("Progress values updated: $_progressValues");
        debugPrint("Current day: $currentDay");
        debugPrint("Days: $_days");
      });
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

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final darkMode = cp.isDark;

    return SizedBox(
      height: 79,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final adjustedDay = currentDay - 1;
          final isSelected = adjustedDay == index;

          final dayLabel = index < _days.length ? _days[index] : "";
          final progressValue =
              index < _progressValues.length ? _progressValues[index] : 0.0;
          final previousValue =
              index < _previousProgressValues.length
                  ? _previousProgressValues[index]
                  : 0.0;

          Color getBgColor() {
            if (isSelected) {
              return cp.widget;
            }
            return Colors.transparent;
          }

          Color getWeekdayColor() {
            if (isSelected) {
              return Colors.white.withOpacity(0.7);
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
            } else if (adjustedDay < index) {
              return cp.border.withOpacity(0.4);
            }
            return cp.disabled;
          }

          return Container(
            width: 45,
            decoration: ShapeDecoration(
              shape: StadiumBorder(),
              color: getBgColor(),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Column(
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      color: getWeekdayColor(),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "${index + 1}",
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
                      key: ValueKey<int>(index),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOut,
                      tween: Tween<double>(
                        begin: previousValue.clamp(0.0, 1.0),
                        end: progressValue.clamp(0.0, 1.0),
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
          );
        }),
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
