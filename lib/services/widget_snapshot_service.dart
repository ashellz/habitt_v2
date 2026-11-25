import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/language_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/services/notification_action_handler.dart';
import 'package:habitt/services/watch_sync_service.dart';
import 'package:habitt/services/widget_snapshot_builder.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Names the home screen widgets are registered under on each platform.
/// They must match the iOS widget `kind`s and the Android receivers.
class HomeWidgetKinds {
  static const appGroupId = 'group.com.shellz.habitt';
  static const snapshotKey = 'habitt_snapshot';

  static const ios = [
    'HabittStreakWidget',
    'HabittStreakWeekWidget',
    'HabittTodayRingWidget',
    'HabittUpNextWidget',
  ];

  static const android = [
    'com.shellz.habitt.widgets.StreakWidgetReceiver',
    'com.shellz.habitt.widgets.StreakWeekWidgetReceiver',
    'com.shellz.habitt.widgets.TodayRingWidgetReceiver',
    'com.shellz.habitt.widgets.UpNextWidgetReceiver',
  ];
}

/// Where a finished snapshot goes. The real one is [HomeWidgetSnapshotWriter];
/// tests pass a fake.
abstract class WidgetSnapshotWriter {
  Future<void> write(String json);
}

/// Saves the snapshot where the widgets read it (App Group defaults on iOS,
/// SharedPreferences on Android) and asks every widget to redraw.
class HomeWidgetSnapshotWriter implements WidgetSnapshotWriter {
  bool _groupSet = false;

  @override
  Future<void> write(String json) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      if (!_groupSet) {
        await HomeWidget.setAppGroupId(HomeWidgetKinds.appGroupId);
        _groupSet = true;
      }
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKinds.snapshotKey,
        json,
      );
    } catch (e) {
      debugPrint('[WIDGETS] saving the snapshot failed: $e');
      return;
    }
    // the Apple Watch app draws the same snapshot (docs/watch_app.md)
    unawaited(WatchSyncService.pushSnapshot(json));
    // each kind on its own: a build without one of them must not stop the rest
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final kinds = isIos ? HomeWidgetKinds.ios : HomeWidgetKinds.android;
    for (final kind in kinds) {
      try {
        await HomeWidget.updateWidget(
          iOSName: isIos ? kind : null,
          qualifiedAndroidName: isIos ? null : kind,
        );
      } catch (e) {
        debugPrint('[WIDGETS] reloading $kind failed: $e');
      }
    }
  }
}

/// Keeps the home screen widgets' snapshot current. Any change to the data it
/// is built from marks it dirty; a burst of changes is written once, after
/// [debounce], and a snapshot equal to the last one written is not written
/// again. See docs/home_widgets.md.
class WidgetSnapshotService {
  WidgetSnapshotService({
    required this.collect,
    required this.writer,
    this.debounce = const Duration(milliseconds: 500),
  });

  /// Builds the current snapshot, or null when the app's data is not loaded.
  final Map<String, dynamic>? Function() collect;
  final WidgetSnapshotWriter writer;
  final Duration debounce;

  Timer? _timer;
  String? _lastWritten;
  Future<void> _writing = Future.value();

  static WidgetSnapshotService? _instance;

  /// The running service, once [start] has been called.
  static WidgetSnapshotService? get instance => _instance;

  /// Starts the service for the app's providers. Call once, after the first
  /// frame, with a context below the MultiProvider.
  static WidgetSnapshotService start(BuildContext context) {
    final habits = context.read<HabitProvider>();
    final stats = context.read<StatsProvider>();
    final colors = context.read<ColorProvider>();
    final language = context.read<LanguageProvider>();
    final state = context.read<StateProvider>();

    final service = WidgetSnapshotService(
      writer: HomeWidgetSnapshotWriter(),
      collect:
          () => _collect(
            habits: habits,
            stats: stats,
            colors: colors,
            language: language,
            state: state,
          ),
    );
    for (final source in <Listenable>[habits, stats, colors, language, state]) {
      source.addListener(service.markDirty);
    }
    _instance = service;
    service.markDirty();
    return service;
  }

  /// Schedules a write after [debounce]; later calls push it back.
  void markDirty() {
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(flush()));
  }

  /// Writes now if the snapshot changed (e.g. when the app is paused).
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    // one write at a time, in order
    return _writing = _writing.then((_) => _writeIfChanged());
  }

  Future<void> _writeIfChanged() async {
    final Map<String, dynamic>? snapshot;
    try {
      snapshot = collect();
    } catch (e, st) {
      debugPrint('[WIDGETS] building the snapshot failed: $e\n$st');
      return;
    }
    if (snapshot == null) return;

    // generatedAt changes on every build, so compare without it
    final comparable = jsonEncode({...snapshot}..remove('generatedAt'));
    if (comparable == _lastWritten) return;

    await writer.write(jsonEncode(snapshot));
    _lastWritten = comparable;
  }

  void dispose() {
    _timer?.cancel();
    if (identical(_instance, this)) _instance = null;
  }

  static Map<String, dynamic>? _collect({
    required HabitProvider habits,
    required StatsProvider stats,
    required ColorProvider colors,
    required LanguageProvider language,
    required StateProvider state,
  }) {
    if (!habits.isInitialized) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final locale = _appLocale(language);
    final localeCode = locale.languageCode;

    final tomorrowHabits =
        habits.habits
            .where(
              (h) =>
                  h.isDeleted != true &&
                  h.isPaused != true &&
                  habits.appearsOnDay(h, tomorrow),
            )
            .map((h) => h.copyResetCompletion())
            .toList()
          ..sort(_appOrder);

    return WidgetSnapshotBuilder.build(
      WidgetSnapshotInput(
        now: now,
        todayHabits: List<Habit>.from(habits.todaysHabits),
        tomorrowHabits: tomorrowHabits,
        statuses: stats.getDayCompletionStatuses(habits),
        dayProgress: stats.getAllDaysProgress(habits),
        streak: stats.perfectDaysStreak,
        tailMisses: stats.perfectDaysTailMisses,
        loc: lookupAppLocalizations(locale),
        localeCode: localeCode,
        customSingulars: state.customSingulars,
        formatTime: (minutes) => _formatTime(minutes, localeCode),
        theme: colors.theme,
        hasHabits: habits.habits.any((h) => h.isDeleted != true),
        watchAcks: WatchSyncService.instance?.acks ?? const [],
      ),
    );
  }

  /// The language the app shows: the one picked in settings, else the
  /// device's if the app supports it, else English.
  static Locale _appLocale(LanguageProvider language) {
    final picked = language.locale;
    if (picked != null) return Locale(picked.languageCode);
    final device = PlatformDispatcher.instance.locale;
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == device.languageCode,
    );
    return Locale(supported ? device.languageCode : 'en');
  }

  /// Clock time the way the app shows it, honouring the device's 24-hour
  /// setting; falls back to the locale's default before the UI exists.
  static String _formatTime(int minutes, String localeCode) {
    final normalized = minutes % (24 * 60);
    final time = TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
    final ctx = NotificationActionHandler.navigatorKey.currentContext;
    if (ctx != null) {
      final material = Localizations.of<MaterialLocalizations>(
        ctx,
        MaterialLocalizations,
      );
      if (material != null) {
        final use24 =
            PlatformDispatcher.instance.alwaysUse24HourFormat ||
            MediaQuery.maybeAlwaysUse24HourFormatOf(ctx) == true;
        return material.formatTimeOfDay(time, alwaysUse24HourFormat: use24);
      }
    }
    return DateFormat.jm(
      localeCode,
    ).format(DateTime(2000, 1, 1, time.hour, time.minute));
  }

  // same order as HabitProvider's today list: category, then order, then id
  static int _appOrder(Habit a, Habit b) {
    final byCategory = a.categoryId.compareTo(b.categoryId);
    if (byCategory != 0) return byCategory;
    final aOrder = a.order <= 0 ? 1 << 30 : a.order;
    final bOrder = b.order <= 0 ? 1 << 30 : b.order;
    final byOrder = aOrder.compareTo(bOrder);
    if (byOrder != 0) return byOrder;
    return a.id.compareTo(b.id);
  }
}
