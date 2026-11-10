import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/update_last_date.dart';

// The new-day check waits for a running sync, so a sync that never ended held
// the new day back (today kept yesterday's completions) until the app was
// killed. It now waits only while the sync shows activity.

void main() {
  setUp(() {
    NewDayGate.reset();
    NewDayGate.stuckSyncLimit = const Duration(milliseconds: 80);
    NewDayGate.stuckSyncPoll = const Duration(milliseconds: 20);
  });

  tearDown(NewDayGate.reset);

  test('a sync with no activity is abandoned and the check goes on', () async {
    var abandoned = 0;
    NewDayGate.syncStarted(
      Completer<void>().future, // never ends
      idleFor: () => const Duration(hours: 9),
      abandon: () => abandoned++,
    );

    await NewDayGate.waitForRunningSync();

    expect(abandoned, 1);
    // nothing left to wait for
    await NewDayGate.waitForRunningSync();
    expect(abandoned, 1);
  });

  test('a slow sync that keeps showing activity is waited for', () async {
    var abandoned = 0;
    var ended = false;
    final sync = Completer<void>();
    NewDayGate.syncStarted(
      sync.future,
      idleFor: () => Duration.zero,
      abandon: () => abandoned++,
    );
    Timer(const Duration(milliseconds: 250), () {
      ended = true;
      sync.complete();
    });

    await NewDayGate.waitForRunningSync();

    expect(ended, isTrue);
    expect(abandoned, 0);
  });

  test('a failed sync ends the wait', () async {
    final sync = Completer<void>();
    NewDayGate.syncStarted(sync.future, idleFor: () => Duration.zero);
    sync.completeError(StateError('offline'));

    await NewDayGate.waitForRunningSync();
  });
}
