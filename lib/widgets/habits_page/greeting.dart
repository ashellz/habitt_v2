import 'dart:math';

import 'package:flutter/material.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:provider/provider.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Greeting extends StatefulWidget {
  const Greeting({super.key});

  @override
  State<Greeting> createState() => _GreetingState();
}

class _GreetingState extends State<Greeting> {
  String? name;
  String? _greeting;
  Locale? _lastLocale;
  _DayPeriod? _lastDayPeriod;
  final _random = Random();

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
    _ensureGreeting();
    final localizations = AppLocalizations.of(context)!;
    final cp = context.watch<ColorProvider>();

    return Column(
      spacing: 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting != null ? "$_greeting," : "${localizations.hello},",
          style: TextStyle(
            color: cp.greyText,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          name ?? "Guest",
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
    final locale = Localizations.localeOf(context);
    final l = AppLocalizations.of(context)!;
    final dayPeriod = _dayPeriodFromHour(DateTime.now().hour);

    final needsUpdate =
        _greeting == null ||
        _lastLocale != locale ||
        _lastDayPeriod != dayPeriod;
    if (!needsUpdate) return;

    final options = _greetingOptions(l, dayPeriod);
    setState(() {
      _lastLocale = locale;
      _lastDayPeriod = dayPeriod;
      _greeting = options[_random.nextInt(options.length)];
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
