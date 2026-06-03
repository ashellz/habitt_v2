import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:provider/provider.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final show = context.watch<PreferencesProvider>().showStreakBadge;

    if (!show || streak == 0) return const SizedBox.shrink();

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/new-svg/streak.svg',
            width: 28,
            height: 28,
          ),
          Positioned(
            bottom: 4,
            child: Text(
              '$streak',
              style: const TextStyle(
                shadows: [
                  Shadow(
                    offset: Offset(0, 0),
                    blurRadius: 4,
                    color: Colors.black45,
                  ),
                ],
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
