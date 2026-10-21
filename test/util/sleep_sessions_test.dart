import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/sleep_sessions.dart';

SleepSegment _segment(DateTime start, DateTime end) =>
    SleepSegment(start: start, end: end);

SleepSegment _wholeSession(DateTime start, DateTime end) =>
    SleepSegment(start: start, end: end, isWholeSession: true);

void main() {
  group('groupSleepSessions', () {
    test('merges stage blocks with short wake-ups into one session', () {
      final sessions = groupSleepSessions([
        _segment(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 2)),
        _segment(DateTime(2026, 3, 21, 2, 30), DateTime(2026, 3, 21, 7)),
      ]);

      expect(sessions, hasLength(1));
      expect(sessions.single.start, DateTime(2026, 3, 20, 23));
      expect(sessions.single.end, DateTime(2026, 3, 21, 7));
      expect(sessions.single.minutes, 450);
    });

    test('keeps a nap apart from the night before it', () {
      final sessions = groupSleepSessions([
        _segment(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 7)),
        _segment(DateTime(2026, 3, 21, 15), DateTime(2026, 3, 21, 15, 40)),
      ]);

      expect(sessions, hasLength(2));
      expect(mainSleepSession(sessions)!.start, DateTime(2026, 3, 20, 23));
    });

    test('returns nothing for no segments', () {
      expect(groupSleepSessions(const []), isEmpty);
      expect(mainSleepSession(const []), isNull);
    });

    test('the gap between stage blocks is not counted as sleep', () {
      final session =
          groupSleepSessions([
            _segment(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 3)),
            _segment(DateTime(2026, 3, 21, 4), DateTime(2026, 3, 21, 7)),
          ]).single;

      expect(session.minutes, 7 * 60);
    });
  });

  group('overlapping samples', () {
    test('two apps recording the same night count it once', () {
      final session =
          groupSleepSessions([
            _segment(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 7)),
            _segment(DateTime(2026, 3, 20, 23, 30), DateTime(2026, 3, 21, 7)),
          ]).single;

      expect(session.minutes, 8 * 60);
    });

    test('a block nested inside another adds nothing', () {
      final session =
          groupSleepSessions([
            _segment(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 7)),
            _segment(DateTime(2026, 3, 21, 1), DateTime(2026, 3, 21, 2)),
          ]).single;

      expect(session.minutes, 8 * 60);
      expect(session.end, DateTime(2026, 3, 21, 7));
    });

    test('a partial overlap only adds the part past the current end', () {
      final session =
          groupSleepSessions([
            _segment(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 5)),
            _segment(DateTime(2026, 3, 21, 4), DateTime(2026, 3, 21, 7)),
          ]).single;

      expect(session.minutes, 8 * 60);
    });

    test('overlap does not make a short night beat a real one', () {
      final sessions = groupSleepSessions([
        // 4h night recorded by three apps
        for (var i = 0; i < 3; i++)
          _segment(DateTime(2026, 3, 21, 2), DateTime(2026, 3, 21, 6)),
        // 6h nap later
        _segment(DateTime(2026, 3, 21, 12), DateTime(2026, 3, 21, 18)),
      ]);

      expect(sessions, hasLength(2));
      expect(mainSleepSession(sessions)!.start, DateTime(2026, 3, 21, 12));
    });
  });

  group('whole-session records', () {
    test('count on their own when a source logs no stages', () {
      final session =
          groupSleepSessions([
            _wholeSession(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 7)),
          ]).single;

      expect(session.start, DateTime(2026, 3, 20, 23));
      expect(session.minutes, 8 * 60);
    });

    test('are dropped where stages exist, so awake time is left out', () {
      final session =
          groupSleepSessions([
            _wholeSession(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 7)),
            _segment(DateTime(2026, 3, 20, 23, 20), DateTime(2026, 3, 21, 3)),
            _segment(DateTime(2026, 3, 21, 3, 30), DateTime(2026, 3, 21, 6)),
          ]).single;

      expect(session.start, DateTime(2026, 3, 20, 23, 20));
      expect(session.end, DateTime(2026, 3, 21, 6));
      expect(session.minutes, 220 + 150);
    });

    test('a stageless record from another night is kept', () {
      final sessions = groupSleepSessions([
        _wholeSession(DateTime(2026, 3, 19, 23), DateTime(2026, 3, 20, 7)),
        _segment(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 7)),
      ]);

      expect(sessions, hasLength(2));
    });
  });

  group('day attribution', () {
    test('23:00 to 13:00 belongs to the day it ends on, past noon', () {
      final session =
          groupSleepSessions([
            _segment(DateTime(2026, 3, 20, 23), DateTime(2026, 3, 21, 13)),
          ]).single;

      expect(session.wakeDay, DateTime(2026, 3, 21));
      expect(session.dayBeforeWake, DateTime(2026, 3, 20));
    });

    test('a 02:30 start still has the day before as its day before', () {
      final session =
          groupSleepSessions([
            _segment(DateTime(2026, 3, 21, 2, 30), DateTime(2026, 3, 21, 10)),
          ]).single;

      expect(session.wakeDay, DateTime(2026, 3, 21));
      expect(session.dayBeforeWake, DateTime(2026, 3, 20));
    });

    test('a night shift sleeping 07:00 to 17:00 wakes on its own day', () {
      final session =
          groupSleepSessions([
            _segment(DateTime(2026, 3, 21, 7), DateTime(2026, 3, 21, 17)),
          ]).single;

      expect(session.wakeDay, DateTime(2026, 3, 21));
    });

    test('day before rolls back across a month boundary', () {
      final session =
          groupSleepSessions([
            _segment(DateTime(2026, 4, 1, 1), DateTime(2026, 4, 1, 8)),
          ]).single;

      expect(session.dayBeforeWake, DateTime(2026, 3, 31));
    });
  });
}
