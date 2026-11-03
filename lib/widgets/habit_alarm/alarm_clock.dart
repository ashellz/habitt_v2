import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';

/// Large current time on the alarm page, like a clock app's ringing screen.
/// Follows the device's 12/24h setting.
class AlarmClock extends StatefulWidget {
  const AlarmClock({super.key});

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

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(_now),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );

    return Text(
      time,
      style: TextStyle(
        color: cp.text,
        fontSize: 96,
        fontWeight: FontWeight.w400,
        height: 1.1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
