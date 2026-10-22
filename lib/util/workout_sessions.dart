import 'package:habitt/models/health_session_detail.dart';

// merges sessions happening at the same time into one session
// this is because sometimes you get multiple because of
// third-part apps or watch and phone at the same time
List<HealthSessionDetail> dedupOverlappingSessions(
  Iterable<HealthSessionDetail> sessions,
) {
  final sorted =
      sessions.where((s) => s.end.isAfter(s.start)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));
  if (sorted.isEmpty) return const [];

  final merged = <HealthSessionDetail>[];
  var group = [sorted.first];
  var groupEnd = sorted.first.end;

  for (final session in sorted.skip(1)) {
    if (session.start.isBefore(groupEnd)) {
      group.add(session);
      if (session.end.isAfter(groupEnd)) groupEnd = session.end;
      continue;
    }
    merged.add(_fold(group, groupEnd));
    group = [session];
    groupEnd = session.end;
  }
  merged.add(_fold(group, groupEnd));

  return merged;
}

HealthSessionDetail _fold(List<HealthSessionDetail> group, DateTime end) {
  var longest = group.first;
  for (final session in group.skip(1)) {
    if (session.duration > longest.duration) longest = session;
  }
  return HealthSessionDetail(
    start: group.first.start,
    end: end,
    workoutType: longest.workoutType,
  );
}
