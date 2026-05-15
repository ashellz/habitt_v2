import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_details/strength_ring.dart';
import 'package:habitt/widgets/stats/consistency_calendar.dart';
import 'package:provider/provider.dart';

class OnboardingStep3 extends StatefulWidget {
  const OnboardingStep3({super.key});

  @override
  State<OnboardingStep3> createState() => _OnboardingStep3State();
}

class _OnboardingStep3State extends State<OnboardingStep3>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _chartAnim;
  late Animation<double> _calendarAnim;
  late Animation<double> _strengthAnim;
  late Animation<double> _flameAnim;

  static Map<DateTime, double> _buildDemoStats(DateTime now) {
    final stats = <DateTime, double>{};

    const fullDaysCurrent = {
      1,
      3,
      4,
      5,
      8,
      10,
      11,
      14,
      15,
      16,
      18,
      22,
      25,
      30,
      31,
    };
    final lastDayCurrent = DateTime(now.year, now.month + 1, 0).day;
    for (int d = 1; d <= lastDayCurrent; d++) {
      final date = DateTime(now.year, now.month, d);
      stats[date] =
          fullDaysCurrent.contains(d) ? 1.0 : 0.2 + ((d * 37) % 70) / 100.0;
    }

    const fullDaysPrev = {2, 4, 6, 9, 12, 13, 17, 19, 20, 23, 24, 27, 28};
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final lastDayPrev = DateTime(prevYear, prevMonth + 1, 0).day;
    for (int d = 1; d <= lastDayPrev; d++) {
      final date = DateTime(prevYear, prevMonth, d);
      stats[date] =
          fullDaysPrev.contains(d) ? 1.0 : 0.15 + ((d * 17 + 41) % 65) / 100.0;
    }

    return stats;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _chartAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
    );
    _calendarAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 0.62, curve: Curves.easeOut),
    );
    _strengthAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.46, 0.78, curve: Curves.easeOut),
    );
    _flameAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.92, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _slide(Widget child, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      builder:
          (context, child) => Opacity(
            opacity: anim.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -40 * (1 - anim.value)),
              child: child,
            ),
          ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    final realNow = DateTime.now();
    final demoToday = DateTime(realNow.year, realNow.month + 1, 0);
    final allStats = _buildDemoStats(realNow);

    const barValues = [60.0, 80.0, 45.0, 90.0, 70.0, 55.0, 100.0];

    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.only(right: 16, left: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bar chart — bars grow from zero driven by _chartAnim
          Positioned(
            left: -16,
            right: -16,
            top: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _chartAnim,
              builder: (context, _) {
                final t = _chartAnim.value;
                return IgnorePointer(
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(enabled: false),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 19.99,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine:
                            (_) => const FlLine(
                              color: Colors.black12,
                              strokeWidth: 1,
                            ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        leftTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                      ),
                      barGroups: List.generate(
                        7,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: barValues[i] * t,
                              color: Colors.black.withValues(alpha: 0.1),
                              width: 50,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      maxY: 100,
                    ),
                    duration: Duration.zero,
                  ),
                );
              },
            ),
          ),

          // Calendar card + overlapping flame circle and strength ring
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Transform.scale(
              scale: 0.9,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Calendar slides in
                  _slide(
                    Padding(
                      padding: const EdgeInsets.only(top: 44),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cp.field,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: ConsistencyCalendar(
                          allStats: allStats,
                          today: demoToday,
                          isDemo: true,
                        ),
                      ),
                    ),
                    _calendarAnim,
                  ),

                  // Flame gradient circle — slides in last
                  Positioned(
                    top: 15,
                    left: -15,
                    child: _slide(const _FlameGradientCircle(), _flameAnim),
                  ),

                  // Strength ring — slides in after calendar
                  Positioned(
                    bottom: -10,
                    right: -10,
                    child: _slide(
                      Transform.scale(
                        scale: 1.3,
                        child: StrengthRing(strength: 0.79),
                      ),
                      _strengthAnim,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom fade
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.2,
              widthFactor: 1.2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [cp.main, cp.main.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlameGradientCircle extends StatelessWidget {
  const _FlameGradientCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF6DA), Color(0xFFFFDFB1)],
        ),
      ),
      child: Transform.rotate(
        angle: -0.2,
        child: Center(
          child: SvgPicture.asset(
            'assets/images/new-svg/streak.svg',
            width: 34,
            height: 34,
          ),
        ),
      ),
    );
  }
}
