import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:provider/provider.dart';

class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final show = context.watch<PreferencesProvider>().showStreakBadge;
    final cp = context.watch<ColorProvider>();

    if (!show || streak == 0) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cp.orange100,
        border: Border.all(color: cp.orange200, width: 1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        spacing: 5,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
            child: SvgPicture.asset(
              "assets/images/new-svg/streak.svg",
              width: 16,
              height: 16,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6, top: 3, bottom: 3),
            child: Text(
              streak.toString(),
              style: TextStyle(
                color: cp.orange300,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
