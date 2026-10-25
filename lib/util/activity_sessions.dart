import 'package:habitt/models/health_session_detail.dart';

// Apple Health stores exercise minutes as one sample per minute of brisk
// activity. Samples this close together belong to the same stretch of activity.
const Duration activityPeriodMaxGap = Duration(minutes: 2);

List<HealthSessionDetail> _sortedSamples(Iterable<HealthSessionDetail> samples) =>
    samples.where((s) => s.end.isAfter(s.start)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));

// time covered by at least one sample, overlapping samples count once
// (watch and phone, or two apps, can report the same minute)
Duration activeTimeCovered(Iterable<HealthSessionDetail> samples) {
  var total = Duration.zero;
  DateTime? coveredUntil;

  for (final sample in _sortedSamples(samples)) {
    final from =
        coveredUntil != null && coveredUntil.isAfter(sample.start)
            ? coveredUntil
            : sample.start;
    if (sample.end.isAfter(from)) {
      total += sample.end.difference(from);
      coveredUntil = sample.end;
    }
  }
  return total;
}

// joins the minute samples into periods of activity for the sessions list,
// so 23 consecutive minutes show as one "10:02 - 10:25" row, not 23 rows
// a period's duration is its whole span, gaps up to [maxGap] included
List<HealthSessionDetail> groupActivityPeriods(
  Iterable<HealthSessionDetail> samples, {
  Duration maxGap = activityPeriodMaxGap,
}) {
  final sorted = _sortedSamples(samples);
  if (sorted.isEmpty) return const [];

  final periods = <HealthSessionDetail>[];
  var start = sorted.first.start;
  var end = sorted.first.end;

  for (final sample in sorted.skip(1)) {
    if (sample.start.difference(end) <= maxGap) {
      if (sample.end.isAfter(end)) end = sample.end;
      continue;
    }
    periods.add(HealthSessionDetail(start: start, end: end));
    start = sample.start;
    end = sample.end;
  }
  periods.add(HealthSessionDetail(start: start, end: end));

  return periods;
}
