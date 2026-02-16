import 'dart:math';

import 'package:cupertino_native/style/sf_symbol.dart';
import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/widgets/default/new_circle_button.dart';
import 'package:habitt/widgets/habits_page/greeting.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPageTopSection extends StatefulWidget {
  const MainPageTopSection({super.key});

  @override
  State<MainPageTopSection> createState() => _MainPageTopSectionState();
}

class _MainPageTopSectionState extends State<MainPageTopSection> {
  String? name;
  int currentDay = DateTime.now().weekday;
  final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final progressValues = [0.22, 0.78, 0.48, 0.62, 0.35, 1.0, 0.55];

  @override
  void initState() {
    super.initState();

    // Loading name
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        name = prefs.getString('name');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        spacing: 20,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Greeting(),
              NewCircleButton(
                svgPath: "assets/images/new-svg/settings.svg",
                cnIcon: CNSymbol("gearshape"),
                onPressed: () {
                  Navigator.pushNamed(context, "/settings");
                },
              ),
            ],
          ),
          SizedBox(
            height: 79,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                Color getBgColor() {
                  if (currentDay == index) {
                    return cp.text;
                  }
                  return Colors.transparent;
                }

                Color getWeekdayColor() {
                  if (currentDay == index) {
                    return cp.bg.withOpacity(0.7);
                  }
                  return cp.greyText;
                }

                Color getDayNumberColor() {
                  if (currentDay == index) {
                    return cp.bg;
                  }
                  return cp.text;
                }

                Color progressColor() {
                  double value = progressValues[index];

                  if (value >= 0.5) return cp.main;
                  if (value >= 0.3) return cp.mid;
                  if (value < 0.3) return cp.fail;
                  return cp.disabled;
                }

                Color emptyProgressColor() {
                  if (currentDay == index) {
                    return cp.progressBarSelected;
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
                          days[index],
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
                          child: CustomPaint(
                            painter: PartialArcPainter(
                              progress: progressValues[index],
                              color: progressColor(),
                              backgroundColor: emptyProgressColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
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
