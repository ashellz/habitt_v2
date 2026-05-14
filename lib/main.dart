import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cupertino_native_better/components/tab_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:habitt/firebase_options.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/pages/home_page.dart';
import 'package:habitt/pages/main_pages/settings_page.dart';
import 'package:habitt/pages/onboarding/onboarding_pages.dart';
import 'package:habitt/providers/calendar_provider.dart';
import 'package:habitt/providers/category_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/providers/notifications_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/services/billing_service.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/profile_image_provider.dart';
import 'package:habitt/services/notification_service.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final tp = await ThemeProvider.initFromPrefs(prefs);
  final languageProvider = LanguageProvider.fromPrefs(prefs);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await BillingService.init();

  await Hive.initFlutter();
  Hive.registerAdapters();
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ScheduleTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(PremadeHabitTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(6)) {
    Hive.registerAdapter(HabitTrackingTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(7)) {
    Hive.registerAdapter(HabitNotificationTimeAdapter());
  }
  if (!Hive.isAdapterRegistered(34)) {
    Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
  }
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize BackupProvider to restore persisted sign-in state
  final backupProvider = BackupProvider();
  await backupProvider.initialize();

  // Initialize NotificationsProvider
  final notificationsProvider = NotificationsProvider(prefs);

  // Initialize ProfileImageProvider and load cached image once
  final profileImageProvider = ProfileImageProvider();
  await profileImageProvider.load();

  runApp(
    MultiProvider(
      providers: [
        // 1. StatsProvider: No dependencies.
        ChangeNotifierProvider(
          create: (_) => StatsProvider(prefs: prefs),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (_) => ColorProvider(prefs)),

        // Independent provider
        ChangeNotifierProvider<ThemeProvider>.value(value: tp),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),

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

        ChangeNotifierProxyProvider<HabitProvider, HabitStatsProvider>(
          create: (_) => HabitStatsProvider(),
          update: (_, habitProvider, previous) {
            final provider = previous ?? HabitStatsProvider();
            provider.attachHabitProvider(habitProvider);
            habitProvider.attachHabitStatsProvider(provider);
            return provider;
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

        // Profile image provider (loads image once at startup)
        ChangeNotifierProvider<ProfileImageProvider>.value(
          value: profileImageProvider,
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
    final languageProvider = context.watch<LanguageProvider>();
    final systemUiOverlayStyle =
        cp.isDark
            ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
            )
            : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
            );

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
      dialogTheme: DialogThemeData(
        backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cp.main,
          foregroundColor: cp.bg,
          shape: const StadiumBorder(),
        ),
      ),
    );

    Widget getHomePage() {
      final didOnboard = widget.prefs.getBool('didOnboard');
      if (didOnboard == null || !didOnboard) {
        return const OnboardingPages();
      } else {
        return const HomePage();
      }
    }

    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;

    final cupertinoTheme = CupertinoThemeData(
      brightness: cp.isDark ? Brightness.dark : Brightness.light,
      primaryColor: cp.main,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(fontFamily: 'Satoshi', color: cp.text),
        actionTextStyle: TextStyle(fontFamily: 'Satoshi', color: cp.text),
        navTitleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: cp.text,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: cp.text,
        ),
        navActionTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: cp.text,
        ),
      ),
    );

    final app =
        isIOS
            ? CupertinoApp(
              navigatorObservers: [CNTabBarRouteObserver()],
              title: 'habitt',
              debugShowCheckedModeBanner: false,
              theme: cupertinoTheme,
              locale: languageProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return Theme(
                  data: theme,
                  child: CupertinoTheme(
                    data: cupertinoTheme,
                    child: DefaultTextStyle.merge(
                      style: TextStyle(fontFamily: 'Satoshi', color: cp.text),
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              },
              routes: {'/settings': (context) => const SettingsPage()},
              home: getHomePage(),
            )
            : MaterialApp(
              navigatorObservers: [CNTabBarRouteObserver()],
              title: 'habitt',
              debugShowCheckedModeBanner: false,
              theme: theme,
              darkTheme: theme,
              themeMode:
                  cp.mode == ColorMode.light
                      ? ThemeMode.light
                      : cp.mode == ColorMode.dark
                      ? ThemeMode.dark
                      : ThemeMode.system,
              locale: languageProvider.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                return DefaultTextStyle.merge(
                  style: TextStyle(fontFamily: 'Satoshi', color: cp.text),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              routes: {'/settings': (context) => const SettingsPage()},
              home: getHomePage(),
            );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: app,
    );
  }
}
