import 'dart:async';

import 'package:flutter/material.dart';

/// Large current time on the alarm page, matching the Pixel Clock ringing
/// screen: Google Sans Flex with rounded terminals (ROND 100), narrowed
/// (wdth 78) and tightly tracked. Values fitted pixel-by-pixel against a Pixel
/// screenshot (393dp wide), see docs/habit_alarms.md. Follows the device's
/// 12/24h setting; the font's contextual alternates raise the colon between
/// digits, like Pixel's.
class AlarmClock extends StatefulWidget {
  const AlarmClock({super.key, required this.color});

  final Color color;

  static const double fontSize = 116;
  static const double _letterSpacing = -4;

  /// Distance from the top of the text box to the vertical centre of the
  /// digits (baseline at ascent 0.966em minus half the 0.74em figure height),
  /// so the page can centre the digits themselves.
  static const double inkCenterFromTop = 69;

  @override
  State<AlarmClock> createState() => _AlarmClockState();
}

class _AlarmClockState extends State<AlarmClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (now.minute != _now.minute) setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  TextStyle _style(double size, double letterSpacing) => TextStyle(
    fontFamily: 'GoogleSansFlex',
    fontSize: size,
    letterSpacing: letterSpacing,
    color: widget.color,
    fontVariations: const [
      FontVariation('ROND', 100),
      FontVariation('wdth', 78),
      FontVariation('wght', 470),
      FontVariation('opsz', 72),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final time = TimeOfDay.fromDateTime(_now);

    final String digits;
    String? period;
    if (use24h) {
      digits = loc.formatTimeOfDay(time, alwaysUse24HourFormat: true);
    } else {
      digits =
          '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:'
          '${loc.formatMinute(time)}';
      period =
          time.period == DayPeriod.am
              ? loc.anteMeridiemAbbreviation
              : loc.postMeridiemAbbreviation;
    }

    return MediaQuery.withNoTextScaling(
      // never wider than the screen (12h on narrow phones)
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Transform.translate(
          // trailing letter spacing would push the centred digits right
          offset: const Offset(AlarmClock._letterSpacing / 2, 0),
          child: Text.rich(
            TextSpan(
              text: digits,
              style: _style(AlarmClock.fontSize, AlarmClock._letterSpacing),
              children: [
                if (period != null)
                  TextSpan(text: ' $period', style: _style(36, 0)),
              ],
            ),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
  }
}
