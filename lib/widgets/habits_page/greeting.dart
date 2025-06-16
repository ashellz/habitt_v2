import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorProvider = context.watch<ColorProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.hello,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorProvider.textColor,
          ),
        ),
        Text(
          name ?? "Guest",
          style: TextStyle(
            fontSize: 38,
            height: 1,
            color: colorProvider.colorScheme.vividColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
