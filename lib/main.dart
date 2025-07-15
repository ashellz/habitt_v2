import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/l10n/l10n.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/pages/home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/pages/other_pages/setup_name_page.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  Hive.registerAdapters();
  await Hive.openBox<Habit>('habits');
  await Hive.openBox<Day>('days');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Set status bar background to white
      statusBarIconBrightness: Brightness.light, // Set icons to dark (black)
      statusBarBrightness: Brightness.dark, // For iOS: dark icons
    ),
  );

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        // 1. StatsProvider: No dependencies.
        ChangeNotifierProvider(create: (_) => StatsProvider(), lazy: false),

        // Independent provider
        ChangeNotifierProvider(create: (_) => ColorProvider(prefs: prefs)),

        // 2. HabitProvider: Depends on StatsProvider.
        ChangeNotifierProxyProvider<StatsProvider, HabitProvider>(
          // `create` is called only once to build the initial instance.
          // The dependency (StatsProvider) is not available here, so we create
          // HabitProvider in its initial state.
          create: (_) => HabitProvider(),

          // `update` is called immediately after `create` and whenever
          // StatsProvider notifies listeners. It reuses the `previous` instance.
          update: (_, stats, previous) {
            // The '!' asserts that `previous` will not be null after `create`.
            // The '..' cascade operator calls the method and returns the object.
            return previous!..updateDependencies(stats);
          },
          lazy: false,
        ),

        // 3. CategoryProvider: Depends on HabitProvider.
        ChangeNotifierProxyProvider<HabitProvider, CategoryProvider>(
          // Create the initial instance of CategoryProvider.
          create: (_) => CategoryProvider(null),

          // Update the existing instance when HabitProvider changes.
          update: (_, habit, previous) => previous!..updateDependencies(habit),
        ),

        // 4. StateProvider: No dependencies.
        ChangeNotifierProvider(create: (_) => StateProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => PreferencesProvider(prefs)),
      ],
      child: MyApp(prefs: prefs),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final colorProvider = context.watch<ColorProvider>();
    final Color seedColor = colorProvider.colorScheme.vividColor;

    Widget getHomePage() {
      final name = widget.prefs.getString('name');

      if (name == null) {
        return SetupNamePage(prefs: widget.prefs, stateSetter: setState);
      } else {
        return const HomePage();
      }
    }

    return MaterialApp(
      title: 'habitt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
        fontFamily: 'Poppins',
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Poppins',
          bodyColor: const Color(0xFF212529),
          displayColor: const Color(0xFF212529),
          decorationColor: const Color(0xFF212529),
        ),
      ),
      themeMode: ThemeMode.dark,
      supportedLocales: L10n.all,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: getHomePage(),
    );
  }
}
