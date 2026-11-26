import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/services/notification_action_handler.dart';
import 'package:habitt/services/watch_action_queue.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The phone side of the watch apps (Apple Watch and Wear OS,
/// docs/watch_app.md): applies the actions the watch sends and remembers
/// which ones were applied, so the next snapshot can tell the watch ([acks]).
class WatchSyncService {
  WatchSyncService({
    required this.store,
    required this.prefs,
    required this.applyAll,
    this.onAcksChanged,
  }) : _acks = List<String>.from(prefs.getStringList(acksKey) ?? const []);

  static const String acksKey = 'watch_recent_acks';
  static const int maxAcks = 50;

  final WatchQueueStore store;
  final SharedPreferences prefs;

  /// Applies the plan's actions; false when the app can't apply anything
  /// yet (habits not loaded, no navigator), so the queue is kept.
  final bool Function(List<WatchAction> actions) applyAll;

  /// Called after [acks] changed, to rewrite the snapshot.
  final VoidCallback? onAcksChanged;

  final List<String> _acks;
  Future<void> _draining = Future.value();

  /// Ids of the last [maxAcks] actions applied or dropped, oldest first.
  List<String> get acks => List.unmodifiable(_acks);

  static WatchSyncService? _instance;
  static WatchSyncService? get instance => _instance;

  /// Starts the service for the running app. Call once after the first frame.
  ///
  /// [afterDrain] runs after actions sent while the app was running (often in
  /// the background, woken by the watch) were applied: it should write the
  /// snapshot right away, before iOS suspends the app again.
  static Future<WatchSyncService?> start({
    VoidCallback? onAcksChanged,
    Future<void> Function()? afterDrain,
  }) async {
    if (!WatchChannel.isAvailable) return null;
    final prefs = await SharedPreferences.getInstance();
    final service = WatchSyncService(
      store: MethodChannelWatchQueueStore(),
      prefs: prefs,
      applyAll: _applyWithApp,
      onAcksChanged: onAcksChanged,
    );
    _instance = service;
    WatchChannel.channel.setMethodCallHandler((call) async {
      if (call.method == 'actionsAvailable') {
        try {
          await service.drain();
          // the habit changes land a moment after applyWatchAction returns
          await Future<void>.delayed(const Duration(milliseconds: 400));
          await afterDrain?.call();
        } finally {
          // lets iOS suspend the app again (see WatchBridge; no-op on Android)
          unawaited(
            WatchChannel.channel
                .invokeMethod('drainDone')
                .catchError((_) => null),
          );
        }
      }
      return null;
    });
    return service;
  }

  /// Sends the snapshot to the paired watch (no-op without one).
  static Future<void> pushSnapshot(String json) async {
    if (!WatchChannel.isAvailable) return;
    try {
      await WatchChannel.channel.invokeMethod('pushSnapshot', json);
    } on MissingPluginException {
      // a build without the bridge
    } catch (e) {
      debugPrint('[WATCH] pushing the snapshot failed: $e');
    }
  }

  /// Applies every queued action. Safe to call any time; runs one at a time.
  Future<void> drain() => _draining = _draining.then((_) => _drain());

  Future<void> _drain() async {
    final all = await store.peek();
    if (all.isEmpty) return;
    // a redelivered action that was already applied must not run again: the
    // user may have changed the habit on the phone since
    final seen = _acks.toSet();
    final repeats = [
      for (final a in all)
        if (seen.contains(a.id)) a.id,
    ];
    if (repeats.isNotEmpty) await store.remove(repeats);
    final queued = [
      for (final a in all)
        if (!seen.contains(a.id)) a,
    ];
    if (queued.isEmpty) return;
    final plan = collapseWatchActions(queued);
    if (plan.apply.isEmpty && plan.superseded.isEmpty) return;

    if (plan.apply.isNotEmpty && !applyAll(plan.apply)) {
      debugPrint('[WATCH] app not ready, keeping ${queued.length} actions');
      return;
    }
    final done = [...plan.superseded, ...plan.apply].map((a) => a.id).toList();
    await store.remove(done);

    _acks.addAll(done);
    if (_acks.length > maxAcks) _acks.removeRange(0, _acks.length - maxAcks);
    await prefs.setStringList(acksKey, _acks);
    onAcksChanged?.call();
    debugPrint(
      '[WATCH] applied ${plan.apply.length}, '
      'superseded ${plan.superseded.length}',
    );
  }

  void dispose() {
    if (identical(_instance, this)) {
      _instance = null;
      if (WatchChannel.isAvailable) {
        WatchChannel.channel.setMethodCallHandler(null);
      }
    }
  }

  /// Applies through [HabitProvider] with the navigator's context, like the
  /// notification "Complete" drain.
  static bool _applyWithApp(List<WatchAction> actions) {
    final ctx = NotificationActionHandler.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return false;
    final habits = ctx.read<HabitProvider>();
    if (!habits.isInitialized) return false;
    final state = ctx.read<StateProvider>();
    for (final a in actions) {
      habits.applyWatchAction(a, ctx, state);
    }
    return true;
  }
}
