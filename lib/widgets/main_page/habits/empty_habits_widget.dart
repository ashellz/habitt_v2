import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

enum EmptyHabitsVariant {
  /// No habits in the app at all.
  noHabits,

  /// Habits exist, but none are scheduled for the day shown.
  noneScheduled,

  /// Habits are scheduled for the day shown, but none has a time range
  /// (plan view only).
  noneTimed,
}

class EmptyHabitsWidget extends StatelessWidget {
  const EmptyHabitsWidget({
    super.key,
    this.variant = EmptyHabitsVariant.noHabits,
    this.isToday = true,
  });

  final EmptyHabitsVariant variant;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    // calendar and clock are line icons, tinted so they stay visible in dark mode
    final Widget image;
    final String text;
    switch (variant) {
      case EmptyHabitsVariant.noHabits:
        image = SvgPicture.asset("assets/images/new-svg/empty-box.svg");
        text = loc.youHaventAddedAnyHabitsYet;
      case EmptyHabitsVariant.noneScheduled:
        image = _lineIcon("assets/images/new-svg/calendar.svg", cp);
        text = isToday ? loc.noHabitsScheduledToday : loc.noHabitsScheduledDay;
      case EmptyHabitsVariant.noneTimed:
        image = _lineIcon("assets/images/new-svg/clock.svg", cp);
        text = isToday ? loc.noTimedHabitsToday : loc.noTimedHabitsDay;
    }

    return Column(
      spacing: 16,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        image,
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: cp.lightGreyText, fontSize: 16),
        ),
      ],
    );
  }

  Widget _lineIcon(String path, ColorProvider cp) {
    return SvgPicture.asset(
      path,
      width: 60,
      height: 60,
      colorFilter: ColorFilter.mode(cp.lightGreyText, BlendMode.srcIn),
    );
  }
}
