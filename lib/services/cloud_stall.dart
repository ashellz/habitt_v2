import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Time limits for cloud calls. Without them a request that never answers
// (a connection Android dropped while the app sat in the background, say)
// kept its sync "running" forever: no other sync could start, and the new-day
// check, which waits for a running sync, never ran.

/// A cloud call made no progress within its time limit. The adapters never
/// swallow it, so it ends the sync, which retries later.
class CloudStallException implements Exception {
  CloudStallException(this.operation, this.limit);

  final String operation;
  final Duration limit;

  @override
  String toString() =>
      'CloudStallException: $operation made no progress in '
      '${limit.inSeconds}s';
}

/// [future], failing with [CloudStallException] if it hasn't completed within
/// [limit].
Future<T> withStallLimit<T>(
  Future<T> future,
  Duration limit,
  String operation,
) => future.timeout(
  limit,
  onTimeout: () => throw CloudStallException(operation, limit),
);

/// An [http.Client] whose requests fail with [CloudStallException] when they
/// stall:
/// - no response within [responseLimit], plus [secondsPerUploadKb]-scaled
///   time for the request body, so a big upload on a slow connection isn't
///   cut off;
/// - a response body that delivers nothing for [bodyStallLimit].
/// On a stall the inner client is closed, which drops its connections, so the
/// request can't still finish later on its own.
class StallGuardClient extends http.BaseClient {
  StallGuardClient(
    this._inner, {
    this.responseLimit = const Duration(seconds: 30),
    this.bodyStallLimit = const Duration(seconds: 30),
    this.uploadBytesPerSecond = 20 * 1024,
  });

  final http.Client _inner;
  final Duration responseLimit;
  final Duration bodyStallLimit;

  /// The slowest upload speed allowed for before a request counts as stalled.
  final int uploadBytesPerSecond;

  /// Time allowed for [request] to get a response.
  @visibleForTesting
  Duration limitFor(http.BaseRequest request) {
    // googleapis sends its upload length as a header, not contentLength
    final length =
        int.tryParse(request.headers['content-length'] ?? '') ??
        request.contentLength ??
        0;
    return responseLimit +
        Duration(milliseconds: length * 1000 ~/ uploadBytesPerSecond);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final what = '${request.method} ${request.url.path}';
    final limit = limitFor(request);
    final http.StreamedResponse response;
    try {
      response = await _inner.send(request).timeout(limit);
    } on TimeoutException {
      _inner.close();
      throw CloudStallException(what, limit);
    }
    return http.StreamedResponse(
      http.ByteStream(_guardBody(response.stream, what)),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  Stream<List<int>> _guardBody(Stream<List<int>> body, String what) {
    late final StreamController<List<int>> out;
    StreamSubscription<List<int>>? sub;
    Timer? timer;

    void arm() {
      timer?.cancel();
      timer = Timer(bodyStallLimit, () {
        sub?.cancel();
        _inner.close();
        out.addError(CloudStallException('$what (body)', bodyStallLimit));
        out.close();
      });
    }

    out = StreamController<List<int>>(
      onListen: () {
        arm();
        sub = body.listen(
          (chunk) {
            arm();
            out.add(chunk);
          },
          onError: (Object e, StackTrace st) {
            timer?.cancel();
            out.addError(e, st);
          },
          onDone: () {
            timer?.cancel();
            out.close();
          },
        );
      },
      // the reader waiting isn't the connection stalling
      onPause: () {
        timer?.cancel();
        sub?.pause();
      },
      onResume: () {
        arm();
        sub?.resume();
      },
      onCancel: () {
        timer?.cancel();
        return sub?.cancel();
      },
    );
    return out.stream;
  }

  @override
  void close() => _inner.close();
}

/// Waits for an operation that reports progress through callbacks (iCloud
/// transfers): [kick] on each progress event, [complete] / [fail] when it
/// ends. [done] fails with [CloudStallException] when no event came for
/// [limit], counted from creation.
class ProgressWatch {
  ProgressWatch(this.operation, this.limit) {
    kick();
  }

  final String operation;
  final Duration limit;
  final Completer<void> _done = Completer<void>();
  Timer? _timer;

  Future<void> get done => _done.future;

  void kick() {
    if (_done.isCompleted) return;
    _timer?.cancel();
    _timer = Timer(limit, () => fail(CloudStallException(operation, limit)));
  }

  void complete() {
    _timer?.cancel();
    if (!_done.isCompleted) _done.complete();
  }

  void fail(Object error, [StackTrace? stackTrace]) {
    _timer?.cancel();
    if (!_done.isCompleted) _done.completeError(error, stackTrace);
  }
}
