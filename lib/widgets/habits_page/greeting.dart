import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Greeting extends StatefulWidget {
  const Greeting({super.key});

  @override
  State<Greeting> createState() => _GreetingState();
}

class _GreetingState extends State<Greeting> {
  static String? _sessionGreeting;
  static final _random = Random();
  String? name;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        name = prefs.getString('name');
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureGreeting();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final cp = context.watch<ColorProvider>();
    final bp = context.watch<BackupProvider>();

    final googleName = bp.currentUser?.displayName;
    final firstName = googleName?.split(' ').first;
    final displayName = name ?? firstName ?? loc.guest;

    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _sessionGreeting != null ? "$_sessionGreeting," : "${loc.hello},",
          style: TextStyle(
            color: cp.greyText,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          displayName,
          style: TextStyle(
            color: cp.text,
            fontSize: 32,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _ensureGreeting() {
    if (_sessionGreeting != null) return;

    final loc = AppLocalizations.of(context)!;
    final dayPeriod = _dayPeriodFromHour(DateTime.now().hour);

    final options = _greetingOptions(loc, dayPeriod);
    setState(() {
      _sessionGreeting = options[_random.nextInt(options.length)];
    });
  }

  List<String> _greetingOptions(AppLocalizations l, _DayPeriod dayPeriod) {
    return [
      _dayPeriodGreeting(l, dayPeriod),
      l.hello,
      l.whatsUp,
      l.goodToSeeYou,
      l.welcomeBack,
      l.helloThere,
      l.hi,
      l.hiThere,
      l.howAreYou,
    ];
  }

  String _dayPeriodGreeting(AppLocalizations l, _DayPeriod period) {
    switch (period) {
      case _DayPeriod.morning:
        return l.goodMorning;
      case _DayPeriod.afternoon:
        return l.goodAfternoon;
      case _DayPeriod.evening:
        return l.goodEvening;
    }
  }

  _DayPeriod _dayPeriodFromHour(int hour) {
    if (hour >= 4 && hour < 12) return _DayPeriod.morning;
    if (hour >= 12 && hour < 19) return _DayPeriod.afternoon;
    return _DayPeriod.evening;
  }
}

enum _DayPeriod { morning, afternoon, evening }
