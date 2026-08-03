import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/models/streak_health.dart';
import 'package:habitt/util/streak_praise.dart';
import 'package:provider/provider.dart';

class NewPerfectDaysStreak extends StatefulWidget {
  const NewPerfectDaysStreak({super.key});

  @override
  State<NewPerfectDaysStreak> createState() => _NewPerfectDaysStreakState();
}

class _NewPerfectDaysStreakState extends State<NewPerfectDaysStreak>
    with SingleTickerProviderStateMixin {
  static String? _sessionCopy;
  static String? _sessionCopyKey;
  static final _random = Random();

  late final AnimationController _controller;
  late final Animation<Offset> _fireSlide;
  late final Animation<double> _bulbFade;
  late final Animation<double> _gradientProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fireSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _bulbFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );

    _gradientProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _copyFor({
    required AppLocalizations loc,
    required String localeCode,
    required StreakHealth health,
    required bool hasProgressToday,
  }) {
    final key = '$health|$hasProgressToday|$localeCode';
    final cached = _sessionCopy;
    if (_sessionCopyKey == key && cached != null) return cached;

    final options = streakCopyOptions(
      loc,
      health: health,
      hasProgressToday: hasProgressToday,
    );
    final picked = options[_random.nextInt(options.length)];
    _sessionCopyKey = key;
    _sessionCopy = picked;
    return picked;
  }

  ({Color left, Color right}) _gradientFor(
    ColorProvider cp,
    StreakHealth health,
  ) {
    return switch (health) {
      StreakHealth.healthy || StreakHealth.dormant => (
        left: cp.leftOrangeGraident,
        right: cp.rightOrangeGradient,
      ),
      StreakHealth.fading => (
        left: cp.leftFadingOrangeGraident, // FFFEEE - 4C2E0E
        right: cp.rightFadingOrangeGradient, // FFF2CF - 75471F
      ),
      StreakHealth.critical => (
        left: cp.leftBlueGraident, // E5F0FB - 0F4E8D
        right: cp.rightBlueGradient, // DFE9FF - 243966
      ),
    };
  }

  Color _glowFor(ColorProvider cp, StreakHealth health) {
    return switch (health) {
      StreakHealth.healthy || StreakHealth.dormant => cp.orange,
      StreakHealth.fading => cp.fadingOrangeCircle.withValues(
        alpha: cp.isDark ? 0.9 : 0.4,
      ),
      StreakHealth.critical => cp.blueCircle,
    };
  }

  Widget _artwork(StreakHealth health) {
    return switch (health) {
      StreakHealth.healthy || StreakHealth.dormant => SvgPicture.asset(
        "assets/images/new-svg/streak.svg",
        width: 94,
        height: 94,
      ),
      StreakHealth.fading => SvgPicture.asset(
        "assets/images/new-svg/streak-fade.svg",
      ),
      StreakHealth.critical => SizedBox(
        width: 130,
        height: 130,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: SvgPicture.asset(
                "assets/images/new-svg/streak.svg",
                width: 94,
                height: 94,
              ),
            ),
            Positioned(
              right: 50,
              bottom: -20,
              child: SvgPicture.asset("assets/images/new-svg/ice-left.svg"),
            ),
            Positioned(
              right: -30,
              bottom: -100,
              child: SvgPicture.asset("assets/images/new-svg/ice-over.svg"),
            ),
          ],
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final statsProvider = context.watch<StatsProvider>();

    final health = statsProvider.perfectDaysHealth;
    if (health == StreakHealth.dormant) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;
    final todayStatus = statsProvider.todayCompletionStatus;

    final displayStreak =
        statsProvider.perfectDaysStreak +
        (todayStatus == DayCompletionStatus.perfect ? 1 : 0);

    final copy = _copyFor(
      loc: loc,
      localeCode: Localizations.localeOf(context).languageCode,
      health: health,
      hasProgressToday: todayStatus == DayCompletionStatus.partial,
    );

    final gradient = _gradientFor(cp, health);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _gradientProgress,
            builder: (context, child) {
              final rightColor =
                  Color.lerp(
                    gradient.left,
                    gradient.right,
                    _gradientProgress.value,
                  )!;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                clipBehavior: Clip.antiAlias,
                height: 82,
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(1.00, 0.00),
                    end: Alignment(0.00, 1.00),
                    colors: [gradient.left, rightColor],
                  ),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: child,
              );
            },
            child: Row(
              spacing: 12,
              children: [
                Text(
                  displayStreak.toString(),
                  style: TextStyle(
                    color: cp.text,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      '${displayStreak == 1 ? loc.day : loc.days} ${loc.streak}',
                      style: TextStyle(
                        color: cp.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      copy,
                      style: TextStyle(
                        color: cp.text.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -20,
            right: -40,
            child: FadeTransition(
              opacity: _bulbFade,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.45,
                height: MediaQuery.of(context).size.width * 0.45,
                decoration: ShapeDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _glowFor(cp, health).withValues(alpha: 0.9),
                      _glowFor(cp, health).withValues(alpha: 0),
                    ],
                  ),
                  shape: OvalBorder(),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: health == StreakHealth.fading ? -55 : -20,
            right: health == StreakHealth.fading ? -24 : 0,
            child: SlideTransition(
              position: _fireSlide,
              child: _artwork(health),
            ),
          ),
        ],
      ),
    );
  }
}
