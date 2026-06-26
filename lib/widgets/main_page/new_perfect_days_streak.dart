import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/streak_praise.dart';
import 'package:provider/provider.dart';

class NewPerfectDaysStreak extends StatefulWidget {
  const NewPerfectDaysStreak({super.key});

  @override
  State<NewPerfectDaysStreak> createState() => _NewPerfectDaysStreakState();
}

class _NewPerfectDaysStreakState extends State<NewPerfectDaysStreak>
    with SingleTickerProviderStateMixin {
  static String? _sessionPraise;
  static String? _sessionLocale;
  static final _random = Random();

  late final AnimationController _controller;
  late final Animation<Offset> _fireSlide;
  late final Animation<double> _bulbFade;
  late final Animation<double> _gradientProgress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensurePraise();
  }

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

  void _ensurePraise() {
    final currentLocale = Localizations.localeOf(context).languageCode;
    if (_sessionPraise != null && _sessionLocale == currentLocale) return;

    _sessionLocale = currentLocale;
    final loc = AppLocalizations.of(context)!;
    final options = streakPraiseOptions(loc);
    setState(() {
      _sessionPraise = options[_random.nextInt(options.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final statsProvider = context.watch<StatsProvider>();
    if (statsProvider.perfectDaysStreak == 0) {
      return SizedBox.shrink();
    }

    final loc = AppLocalizations.of(context)!;

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
                    cp.leftOrangeGraident,
                    cp.rightOrangeGradient,
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
                    colors: [cp.leftOrangeGraident, rightColor],
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
                  statsProvider.perfectDaysStreak.toString(),
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
                      '${statsProvider.perfectDaysStreak == 1 ? loc.day : loc.days} ${loc.streak}',
                      style: TextStyle(
                        color: cp.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _sessionPraise ?? loc.youreDoingGreat,
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
                      cp.orange.withOpacity(0.9),
                      cp.orange.withOpacity(0),
                    ],
                  ),
                  shape: OvalBorder(),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 0,
            child: SlideTransition(
              position: _fireSlide,
              child: SvgPicture.asset(
                "assets/images/new-svg/streak.svg",
                width: 94,
                height: 94,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
