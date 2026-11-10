import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/services/cloud_stall.dart';
import 'package:http/http.dart' as http;

// Cloud calls get time limits: a request that never answers (a connection
// Android dropped while the app was in the background) used to keep its sync
// running forever, blocking every later sync and the new-day check.

const _limit = Duration(milliseconds: 60);

/// An inner client answering with [respond], recording close().
class _Inner extends http.BaseClient {
  _Inner(this.respond);

  final Future<http.StreamedResponse> Function(http.BaseRequest) respond;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      respond(request);

  @override
  void close() => closed = true;
}

StallGuardClient _guard(_Inner inner) => StallGuardClient(
  inner,
  responseLimit: _limit,
  bodyStallLimit: _limit,
  uploadBytesPerSecond: 1000,
);

Stream<List<int>> _chunks(int count, Duration gap) async* {
  for (var i = 0; i < count; i++) {
    await Future<void>.delayed(gap);
    yield [i];
  }
}

void main() {
  group('StallGuardClient', () {
    test(
      'a request that never answers stalls and drops the connection',
      () async {
        final inner = _Inner((_) => Completer<http.StreamedResponse>().future);
        final client = _guard(inner);

        await expectLater(
          client.get(Uri.parse('https://example.com/files')),
          throwsA(isA<CloudStallException>()),
        );
        expect(inner.closed, isTrue);
      },
    );

    test('a body that stops delivering stalls', () async {
      final body = StreamController<List<int>>();
      body.add([1, 2, 3]); // then nothing
      final inner = _Inner(
        (_) async => http.StreamedResponse(body.stream, 200),
      );
      final client = _guard(inner);

      await expectLater(
        client.get(Uri.parse('https://example.com/file')),
        throwsA(isA<CloudStallException>()),
      );
      expect(inner.closed, isTrue);
      await body.close();
    });

    test('a slow body that keeps delivering is not cut off', () async {
      // longer than the limit in total, but never quiet that long
      final inner = _Inner(
        (_) async => http.StreamedResponse(
          _chunks(6, const Duration(milliseconds: 25)),
          200,
        ),
      );
      final client = _guard(inner);

      final response = await client.get(Uri.parse('https://example.com/file'));

      expect(response.bodyBytes, [0, 1, 2, 3, 4, 5]);
      expect(inner.closed, isFalse);
    });

    test('an upload gets extra time for its size', () {
      final client = _guard(
        _Inner((_) => Completer<http.StreamedResponse>().future),
      );
      final small = http.Request('POST', Uri.parse('https://example.com/u'));
      // googleapis sends the length as a header
      final big = http.Request('POST', Uri.parse('https://example.com/u'))
        ..headers['content-length'] = '5000';

      expect(client.limitFor(small), _limit);
      expect(client.limitFor(big), _limit + const Duration(seconds: 5));
    });
  });

  group('ProgressWatch', () {
    test('fails when progress stays quiet', () async {
      final watch = ProgressWatch('upload', _limit);
      await expectLater(watch.done, throwsA(isA<CloudStallException>()));
    });

    test('progress keeps it alive until it completes', () async {
      final watch = ProgressWatch('upload', _limit);
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        watch.kick();
      }
      watch.complete();
      await expectLater(watch.done, completes);
    });
  });

  test('withStallLimit fails a call that never answers', () async {
    await expectLater(
      withStallLimit(Completer<void>().future, _limit, 'token'),
      throwsA(isA<CloudStallException>()),
    );
  });
}
