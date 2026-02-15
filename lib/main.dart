import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitt/firebase_options.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/l10n/l10n.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/pages/new_habits_page.dart';
import 'package:habitt/pages/other_pages/setup_name_page.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/services/billing_service.dart';
import 'package:habitt/services/new_color_service.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final tp = await ThemeProvider.initFromPrefs(prefs);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await BillingService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent, // ← bottom nav bar
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent, // ← top status bar
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Hive.initFlutter();
  Hive.registerAdapters();
  await Hive.openBox<Habit>('habits');
  await Hive.openBox<Day>('days');

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Main notifications',
        channelDescription: 'Notification channel for production',
      ),
    ],
    // Channel groups are only visual and are not required
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'basic_channel_group',
        channelGroupName: 'Basic group',
      ),
    ],
    debug: kDebugMode,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Set status bar background to white
      statusBarIconBrightness: Brightness.light, // Set icons to dark (black)
      statusBarBrightness: Brightness.dark, // For iOS: dark icons
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize BackupProvider to restore persisted sign-in state
  final backupProvider = BackupProvider();
  await backupProvider.initialize();

  // Initialize NotificationsProvider
  final notificationsProvider = NotificationsProvider(prefs);

  runApp(
    MultiProvider(
      providers: [
        // 1. StatsProvider: No dependencies.
        ChangeNotifierProvider(create: (_) => StatsProvider(), lazy: false),
        ChangeNotifierProvider(create: (_) => ColorProvider()),

        // Independent provider
        ChangeNotifierProvider<ThemeProvider>.value(value: tp),

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
          update:
              (_, habitProvider, previous) =>
                  previous!..updateDependencies(habitProvider),
        ),

        // 4. StateProvider: No dependencies.
        ChangeNotifierProvider(create: (_) => StateProvider(prefs)),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => PreferencesProvider(prefs)),
        ChangeNotifierProvider<NotificationsProvider>.value(
          value: notificationsProvider,
        ),

        // 5. BackupProvider: Depends on HabitProvider for post-merge refresh.
        ChangeNotifierProxyProvider<HabitProvider, BackupProvider>(
          create: (_) => backupProvider,
          update: (_, habitProvider, previous) {
            habitProvider.attachBackupProvider(previous!);
            return previous..attachHabitProvider(habitProvider);
          },
        ),
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
  void initState() {
    super.initState();
    _scheduleNotifications();
  }

  Future<void> _scheduleNotifications() async {
    final notificationsProvider = context.read<NotificationsProvider>();
    final isAllowed = await NotificationService.areNotificationsAllowed();

    // Only schedule if user has granted permissions
    if (isAllowed) {
      await NotificationService.scheduleAllNotifications(notificationsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();

    // Choose base ColorScheme based on theme provider state
    final baseScheme =
        cp.isDark
            ? ColorScheme.dark(
              primary: cp.main,
              secondary: cp.secondaryButton,
              surface: cp.bg,
              error: cp.fail,
              onPrimary: cp.bg,
              onSecondary: cp.text,
              onSurface: cp.text,
              onError: cp.bg,
              background: cp.bg,
            )
            : ColorScheme.light(
              primary: cp.main,
              secondary: cp.secondaryButton,
              surface: cp.bg,
              error: cp.fail,
              onPrimary: cp.bg,
              onSecondary: cp.text,
              onSurface: cp.text,
              onError: cp.bg,
              background: cp.bg,
            );

    final theme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Satoshi',
      colorScheme: baseScheme,
      scaffoldBackgroundColor: cp.bg,
      textTheme: ThemeData(
        brightness: cp.isDark ? Brightness.dark : Brightness.light,
      ).textTheme.apply(
        fontFamily: 'Satoshi',
        bodyColor: cp.text,
        displayColor: cp.text,
      ),
      dialogTheme: DialogThemeData(backgroundColor: cp.habitBg),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cp.main,
          foregroundColor: cp.bg,
          shape: const StadiumBorder(),
        ),
      ),
    );

    Widget getHomePage() {
      final name = widget.prefs.getString('name');
      if (name == null) {
        return SetupNamePage(prefs: widget.prefs, stateSetter: setState);
      } else {
        return const NewHabitsPage();
      }
    }

    return MaterialApp(
      title: 'habitt',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: cp.isDark ? ThemeMode.dark : ThemeMode.light,
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
