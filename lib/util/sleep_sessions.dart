/// One raw sleep sample from Health: a stage block (asleep / core / deep /
/// REM), or, with [isWholeSession], a whole recorded night from Health
/// Connect's session record — which also spans the time spent awake in it.
class SleepSegment {
  final DateTime start;
  final DateTime end;
  final bool isWholeSession;

  const SleepSegment({
    required this.start,
    required this.end,
    this.isWholeSession = false,
  });

  bool overlaps(SleepSegment other) =>
      start.isBefore(other.end) && other.start.isBefore(end);
}

/// A run of [SleepSegment]s with no meaningful break between them — one
/// night's sleep, or one nap.
class SleepSession {
  final DateTime start;
  final DateTime end;
  final double minutes;

  const SleepSession({
    required this.start,
    required this.end,
    required this.minutes,
  });

  /// The day the person woke up on — the day this session's sleep duration
  /// and wake time belong to.
  DateTime get wakeDay => DateTime(end.year, end.month, end.day);

  /// The day before [wakeDay], for a bedtime counted on the day before
  /// waking up.
  DateTime get dayBeforeWake => DateTime(end.year, end.month, end.day - 1);
}

/// Samples closer together than this belong to the same session. Long
/// enough to bridge a night's wake-ups, short enough to keep a nap apart
/// from the sleep before it.
const Duration sleepSessionMaxGap = Duration(hours: 3);

/// Merges [segments] into sessions, splitting wherever the gap between one
/// segment's end and the next's start exceeds [maxGap].
///
/// A session's [SleepSession.minutes] is the time covered by at least one
/// segment, so samples that overlap — two apps recording the same night, or
/// a stage inside a broader asleep block — are only counted once. A
/// whole-session segment is dropped wherever a stage segment overlaps it,
/// so its awake time doesn't count when the stages are known.
List<SleepSession> groupSleepSessions(
  Iterable<SleepSegment> segments, {
  Duration maxGap = sleepSessionMaxGap,
}) {
  final stages = segments.where((s) => !s.isWholeSession).toList();
  final sorted =
      segments
          .where((s) => !s.isWholeSession || !stages.any(s.overlaps))
          .where((s) => s.end.isAfter(s.start))
          .toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  if (sorted.isEmpty) return const [];

  final sessions = <SleepSession>[];
  var start = sorted.first.start;
  var end = sorted.first.end;
  var covered = end.difference(start);

  for (final segment in sorted.skip(1)) {
    if (segment.start.difference(end) > maxGap) {
      sessions.add(_session(start, end, covered));
      start = segment.start;
      end = segment.end;
      covered = end.difference(start);
      continue;
    }
    // Sorted by start, so only the part past the current end is new.
    final newFrom = segment.start.isAfter(end) ? segment.start : end;
    if (segment.end.isAfter(newFrom)) {
      covered += segment.end.difference(newFrom);
      end = segment.end;
    }
  }
  sessions.add(_session(start, end, covered));

  return sessions;
}

SleepSession _session(DateTime start, DateTime end, Duration covered) =>
    SleepSession(start: start, end: end, minutes: covered.inSeconds / 60);

/// The session with the most sleep in it, or `null` for an empty list —
/// the night's sleep, as opposed to a nap beside it.
SleepSession? mainSleepSession(Iterable<SleepSession> sessions) {
  SleepSession? main;
  for (final session in sessions) {
    if (main == null || session.minutes > main.minutes) main = session;
  }
  return main;
}
