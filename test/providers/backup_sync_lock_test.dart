import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Only one sync runs at a time. syncState turns to syncing only after the
// new-day check and the key sync, so the guard is taken before performSync's
// first await: syncs asked for together (launch/resume plus the periodic timer,
// say) used to both get through, run the whole cycle twice and optimize twice
// over one counter (it went down to -20).

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NewDayGate.reset();
  });

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
}
