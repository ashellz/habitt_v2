import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/services/cloud_storage_adapter.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Only one sync runs at a time. syncState turns to syncing only after the
// new-day check and the key sync, so the guard is taken before performSync's
// first await: syncs asked for together (launch/resume plus the periodic timer,
// say) used to both get through, run the whole cycle twice and optimize twice
// over one counter (it went down to -20).

/// An adapter whose key download hangs until the test answers it.
class _HangingAdapter implements CloudStorageAdapter {
  final keyDownloads = <Completer<Uint8List?>>[];

  @override
  Future<Uint8List?> downloadKeyFile() {
    final c = Completer<Uint8List?>();
    keyDownloads.add(c);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NewDayGate.reset();
  });

  tearDown(NewDayGate.reset);

  test('syncs asked for together start once', () async {
    final bp = BackupProvider();

    await Future.wait([
      bp.performSync(),
      bp.performSync(false, SyncMode.uploadOnly),
      bp.performSync(true),
      bp.performSync(false, SyncMode.syncOnly),
    ]);

    expect(bp.debugStartedSyncRuns, 1);
  });

  test('the next sync starts once the running one ended', () async {
    final bp = BackupProvider();

    await bp.performSync();
    await bp.performSync(false, SyncMode.uploadOnly);

    expect(bp.debugStartedSyncRuns, 2);
  });

  test('a stuck sync is abandoned by the new-day check', () async {
    NewDayGate.stuckSyncLimit = const Duration(milliseconds: 80);
    NewDayGate.stuckSyncPoll = const Duration(milliseconds: 20);
    final adapter = _HangingAdapter();
    final bp = BackupProvider()..debugUseAdapter(adapter);

    final stuck = bp.performSync();
    await pumpEventQueue();
    expect(adapter.keyDownloads, hasLength(1), reason: 'stuck on the key');

    // what the new-day check does before resetting the day
    await NewDayGate.waitForRunningSync();
    // whoever awaited the sync isn't left waiting on the stuck call
    await stuck;

    expect(bp.syncState, SyncState.error);
    expect(bp.lastError, contains('no progress'));

    // the lock is free again
    unawaited(bp.performSync());
    await pumpEventQueue();
    expect(bp.debugStartedSyncRuns, 2);

    // the stuck call finally answers: the abandoned sync stops there and
    // leaves the new sync's lock alone
    adapter.keyDownloads.first.complete(null);
    await pumpEventQueue();
    await bp.performSync();
    expect(bp.debugStartedSyncRuns, 2);
  });
}
