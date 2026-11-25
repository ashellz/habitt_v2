import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/services/watch_action_queue.dart';
import 'package:habitt/services/watch_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _raw(
  String id, {
  int v = 1,
  String type = 'complete',
  int habitId = 1,
  String day = '2026-11-25',
  String at = '2026-11-25T08:00:00.000',
  int? value,
}) => {
  'v': v,
  'id': id,
  'type': type,
  'habitId': habitId,
  'day': day,
  'at': at,
  if (value != null) 'value': value,
};

WatchAction _a(
  String id, {
  int v = 1,
  String type = 'complete',
  int habitId = 1,
  String day = '2026-11-25',
  String at = '2026-11-25T08:00:00.000',
  int? value,
}) =>
    WatchAction.fromJson(
      _raw(id, v: v, type: type, habitId: habitId, day: day, at: at, value: value),
    )!;

class _FakeStore implements WatchQueueStore {
  _FakeStore(this.items);
  final List<WatchAction> items;
  final removed = <String>[];

  @override
  Future<List<WatchAction>> peek() async => List.of(items);

  @override
  Future<void> remove(Iterable<String> ids) async {
    removed.addAll(ids);
    items.removeWhere((a) => ids.contains(a.id));
  }
}

void main() {
  group('WatchAction.fromJson', () {
    test('reads every field, 16 digit ids included', () {
      final a = _a(
        'x',
        type: 'setAmount',
        habitId: 1795574050137094,
        value: 8,
        at: '2026-11-25T08:31:02.000',
      );
      expect(a.type, WatchActionType.setAmount);
      expect(a.habitId, 1795574050137094);
      expect(a.day, DateTime(2026, 11, 25));
      expect(a.value, 8);
      expect(a.at, DateTime(2026, 11, 25, 8, 31, 2));
      expect(a.isSupported, isTrue);
    });

    test('tolerates unknown fields and types, rejects broken ones', () {
      final a = WatchAction.fromJson({..._raw('x', type: 'teleport'), 'new': 1});
      expect(a!.type, WatchActionType.unknown);
      expect(WatchAction.fromJson({'id': 'x'}), isNull);
      expect(WatchAction.fromJson('nope'), isNull);
      expect(WatchAction.fromJson(_raw('x', day: 'soon')), isNull);
    });
  });

  group('collapseWatchActions', () {
    test('keeps the newest action per habit and day', () {
      final plan = collapseWatchActions([
        _a('1', type: 'setAmount', value: 5, at: '2026-11-25T08:00:00'),
        _a('2', type: 'setAmount', value: 8, at: '2026-11-25T08:00:05'),
        _a('3', habitId: 2),
      ]);
      expect(plan.apply.map((a) => a.id), ['3', '2']);
      expect(plan.apply.last.value, 8);
      expect(plan.superseded.map((a) => a.id), ['1']);
    });

    test('an older action arriving late does not win', () {
      final plan = collapseWatchActions([
        _a('new', type: 'uncomplete', at: '2026-11-25T09:00:00'),
        _a('old', at: '2026-11-25T08:00:00'),
      ]);
      expect(plan.apply.single.id, 'new');
      expect(plan.superseded.single.id, 'old');
    });

    test('the same habit on two days are two actions', () {
      final plan = collapseWatchActions([
        _a('1', day: '2026-11-24'),
        _a('2', day: '2026-11-25'),
      ]);
      expect(plan.apply.length, 2);
    });

    test('duplicates by id count once', () {
      final plan = collapseWatchActions([_a('1'), _a('1')]);
      expect(plan.apply.length, 1);
      expect(plan.superseded, isEmpty);
    });

    test('unknown versions are kept aside, not applied', () {
      final plan = collapseWatchActions([_a('1', v: 2), _a('2', habitId: 3)]);
      expect(plan.unsupported.single.id, '1');
      expect(plan.apply.single.id, '2');
    });
  });

  group('WatchSyncService.drain', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('applies, removes and acknowledges; keeps unsupported', () async {
      final store = _FakeStore([
        _a('a', type: 'setAmount', value: 5, at: '2026-11-25T08:00:00'),
        _a('b', type: 'setAmount', value: 8, at: '2026-11-25T08:00:05'),
        _a('future', v: 9, habitId: 2),
      ]);
      final applied = <String>[];
      var acksChanged = 0;
      final service = WatchSyncService(
        store: store,
        prefs: prefs,
        applyAll: (actions) {
          applied.addAll(actions.map((a) => a.id));
          return true;
        },
        onAcksChanged: () => acksChanged++,
      );

      await service.drain();

      expect(applied, ['b']);
      expect(store.removed, unorderedEquals(['a', 'b']));
      expect(store.items.single.id, 'future');
      expect(service.acks, unorderedEquals(['a', 'b']));
      expect(prefs.getStringList(WatchSyncService.acksKey), service.acks);
      expect(acksChanged, 1);
    });

    test('an action applied before is removed, not applied again', () async {
      final store = _FakeStore([_a('a')]);
      final applied = <String>[];
      final service = WatchSyncService(
        store: store,
        prefs: prefs,
        applyAll: (actions) {
          applied.addAll(actions.map((a) => a.id));
          return true;
        },
      );
      await service.drain();
      store.items.add(_a('a')); // redelivered
      await service.drain();
      expect(applied, ['a']);
      expect(store.items, isEmpty);
    });

    test('keeps the queue when the app is not ready', () async {
      final store = _FakeStore([_a('a')]);
      final service = WatchSyncService(
        store: store,
        prefs: prefs,
        applyAll: (_) => false,
      );
      await service.drain();
      expect(store.items.single.id, 'a');
      expect(service.acks, isEmpty);
    });

    test('remembers only the newest 50 acks, across restarts', () async {
      final store = _FakeStore([
        for (int i = 0; i < 60; i++) _a('id$i', habitId: i),
      ]);
      final service = WatchSyncService(
        store: store,
        prefs: prefs,
        applyAll: (_) => true,
      );
      await service.drain();
      expect(service.acks.length, 50);

      final again = WatchSyncService(
        store: _FakeStore([]),
        prefs: prefs,
        applyAll: (_) => true,
      );
      expect(again.acks, service.acks);
    });
  });
}
