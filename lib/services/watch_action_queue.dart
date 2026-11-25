import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One change made on the watch (Apple Watch or Wear OS, docs/watch_app.md). Values are
/// absolute ("set 8 pages"), never increments, so a resend is harmless.
class WatchAction {
  /// Action versions this app can apply. Add to it, never remove: an older
  /// watch may still send an old version.
  static const Set<int> supportedVersions = {1};

  final int v;
  final String id;
  final WatchActionType type;
  final int habitId;
  final DateTime day;

  /// setAmount: the count. setDuration: seconds.
  final int? value;

  /// When the user made the change, watch local time; orders the actions.
  final DateTime at;

  const WatchAction({
    required this.v,
    required this.id,
    required this.type,
    required this.habitId,
    required this.day,
    required this.at,
    this.value,
  });

  bool get isSupported => supportedVersions.contains(v);

  /// Parses one queued action; null when it is unreadable. An unknown `type`
  /// is only an error for a supported version: a newer watch may add types.
  static WatchAction? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final v = raw['v'];
    final id = raw['id'];
    final habitId = raw['habitId'];
    final day = raw['day'] is String ? DateTime.tryParse(raw['day']) : null;
    final at = raw['at'] is String ? DateTime.tryParse(raw['at']) : null;
    if (v is! int || id is! String || habitId is! num || day == null) {
      return null;
    }
    final type = WatchActionType.values.asNameMap()[raw['type']];
    final value = raw['value'];
    return WatchAction(
      v: v,
      id: id,
      type: type ?? WatchActionType.unknown,
      habitId: habitId.toInt(),
      day: DateTime(day.year, day.month, day.day),
      at: at ?? DateTime.fromMillisecondsSinceEpoch(0),
      value: value is num ? value.toInt() : null,
    );
  }
}

enum WatchActionType { complete, uncomplete, setAmount, setDuration, unknown }

/// What [collapseWatchActions] decided for the queued actions.
class WatchActionPlan {
  /// To apply now, oldest first: the newest action per habit and day.
  final List<WatchAction> apply;

  /// Older actions for a habit and day that a newer one replaces. Removed
  /// from the queue and acknowledged without being applied.
  final List<WatchAction> superseded;

  /// From a newer watch than this app understands: left in the queue until
  /// an app update can apply them.
  final List<WatchAction> unsupported;

  const WatchActionPlan({
    required this.apply,
    required this.superseded,
    required this.unsupported,
  });
}

/// Dedupes by id, keeps unsupported versions aside, and keeps only the newest
/// action (by `at`, then queue order) for each habit and day.
WatchActionPlan collapseWatchActions(List<WatchAction> queued) {
  final seen = <String>{};
  final unsupported = <WatchAction>[];
  final newest = <String, WatchAction>{};
  final superseded = <WatchAction>[];

  for (final a in queued) {
    if (!seen.add(a.id)) continue;
    if (!a.isSupported) {
      unsupported.add(a);
      continue;
    }
    final key = '${a.habitId}|${a.day.toIso8601String()}';
    final current = newest[key];
    if (current == null || !a.at.isBefore(current.at)) {
      if (current != null) superseded.add(current);
      newest[key] = a;
    } else {
      superseded.add(a);
    }
  }

  final apply = newest.values.toList()..sort((a, b) => a.at.compareTo(b.at));
  return WatchActionPlan(
    apply: apply,
    superseded: superseded,
    unsupported: unsupported,
  );
}

/// Where received watch actions wait to be applied. The native bridge owns
/// the queue (`WatchBridge` on iOS appends from the WatchConnectivity
/// callbacks, `WearBridge` on Android from the Wear OS listener service), so
/// reads and removals go through it and never race an append.
abstract class WatchQueueStore {
  Future<List<WatchAction>> peek();
  Future<void> remove(Iterable<String> ids);
}

/// The `habitt/watch` method channel to `ios/Runner/WatchBridge.swift` and
/// `android/app/.../watch/WearBridge.kt`.
class WatchChannel {
  static const MethodChannel channel = MethodChannel('habitt/watch');

  /// iOS (`WatchBridge.swift`, Apple Watch) and Android (`WearBridge.kt`,
  /// Wear OS).
  static bool get isAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
}

class MethodChannelWatchQueueStore implements WatchQueueStore {
  @override
  Future<List<WatchAction>> peek() async {
    if (!WatchChannel.isAvailable) return const [];
    try {
      final raw = await WatchChannel.channel.invokeMethod<String>(
        'peekActions',
      );
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final item in list)
          if (WatchAction.fromJson(item) case final a?) a,
      ];
    } catch (e) {
      debugPrint('[WATCH] reading the action queue failed: $e');
      return const [];
    }
  }

  @override
  Future<void> remove(Iterable<String> ids) async {
    if (!WatchChannel.isAvailable || ids.isEmpty) return;
    try {
      await WatchChannel.channel.invokeMethod('removeActions', ids.toList());
    } catch (e) {
      debugPrint('[WATCH] removing applied actions failed: $e');
    }
  }
}
