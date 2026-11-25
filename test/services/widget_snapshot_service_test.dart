import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/services/widget_snapshot_service.dart';

class _FakeWriter implements WidgetSnapshotWriter {
  final writes = <String>[];

  @override
  Future<void> write(String json) async => writes.add(json);
}

void main() {
  late _FakeWriter writer;
  late Map<String, dynamic>? current;
  late int builds;
  // made inside each fakeAsync zone, so its writes run on the fake clock
  late WidgetSnapshotService Function() make;

  setUp(() {
    writer = _FakeWriter();
    current = {'v': 1, 'generatedAt': 't0', 'done': 0};
    builds = 0;
    make =
        () => WidgetSnapshotService(
          writer: writer,
          collect: () {
            builds++;
            final c = current;
            return c == null ? null : {...c, 'generatedAt': 't$builds'};
          },
        );
  });

  test('a burst of changes is written once, after the debounce', () {
    fakeAsync((async) {
      final service = make();
      for (int i = 0; i < 10; i++) {
        service.markDirty();
        async.elapse(const Duration(milliseconds: 100));
      }
      expect(writer.writes, isEmpty);
      async.elapse(const Duration(milliseconds: 500));
      expect(writer.writes, hasLength(1));
      expect(builds, 1);
    });
  });

  test('an unchanged snapshot is not written again', () {
    fakeAsync((async) {
      final service = make();
      service.markDirty();
      async.elapse(const Duration(seconds: 1));
      service.markDirty();
      async.elapse(const Duration(seconds: 1));
      expect(writer.writes, hasLength(1));

      current = {'v': 1, 'done': 1};
      service.markDirty();
      async.elapse(const Duration(seconds: 1));
      expect(writer.writes, hasLength(2));
      expect(jsonDecode(writer.writes.last)['done'], 1);
    });
  });

  test('flush writes at once and cancels the pending write', () {
    fakeAsync((async) {
      final service = make();
      service.markDirty();
      service.flush();
      async.flushMicrotasks();
      expect(writer.writes, hasLength(1));
      async.elapse(const Duration(seconds: 1));
      expect(writer.writes, hasLength(1));
    });
  });

  test('nothing is written before the app has loaded its data', () {
    fakeAsync((async) {
      final service = make();
      current = null;
      service.markDirty();
      async.elapse(const Duration(seconds: 1));
      expect(writer.writes, isEmpty);
    });
  });

  test('a failing build is skipped and later changes still write', () {
    fakeAsync((async) {
      var fail = true;
      final s = WidgetSnapshotService(
        writer: writer,
        collect: () => fail ? throw StateError('boom') : {'v': 1},
      );
      s.markDirty();
      async.elapse(const Duration(seconds: 1));
      expect(writer.writes, isEmpty);
      fail = false;
      s.markDirty();
      async.elapse(const Duration(seconds: 1));
      expect(writer.writes, hasLength(1));
    });
  });
}
