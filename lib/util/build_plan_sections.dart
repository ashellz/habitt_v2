import 'package:habitt/models/habit.dart';

const int _minutesInDay = 24 * 60;

class PlanEntry {
  const PlanEntry({
    required this.habit,
    required this.start,
    required this.end,
    required this.isCurrent,
  });

  final Habit habit;

  /// Placement on the day's timeline in minutes, end already resolved to
  /// 1440 for habits that run until midnight.
  final int start;
  final int end;

  /// The habit's interval contains the current time (today only).
  final bool isCurrent;
}

class PlanSection {
  const PlanSection({required this.start, required this.entries});

  /// Title of the section, minutes since midnight.
  final int start;
  final List<PlanEntry> entries;
}

/// Lays out a day's timed habits for the plan view.
///
/// Habits are sorted by start, then end (shorter first), then category order,
/// then order. A habit opens a new section when it starts at or after the end
/// of the habit right before it, so each habit shows once, under its start.
///
/// [nowMinutes] is the current time when the day shown is today, otherwise
/// null (no highlight, no overnight carry-over). A habit that crosses midnight
/// shows under 00:00 while last night's run is still going, but only when it
/// was scheduled yesterday ([scheduledYesterdayIds]); otherwise it shows under
/// its start, running until midnight.
List<PlanSection> buildPlanSections({
  required List<Habit> habits,
  int? nowMinutes,
  Set<int> scheduledYesterdayIds = const {},
  Map<int, int> categoryRank = const {},
}) {
  final entries = <PlanEntry>[];

  for (final habit in habits) {
    if (!habit.timeIntervalEnabled) continue;

    final rawStart = habit.timeIntervalStart % _minutesInDay;
    final rawEnd = habit.timeIntervalEnd % _minutesInDay;
    // an end of 00:00 means the habit runs until midnight
    final end = rawEnd == 0 ? _minutesInDay : rawEnd;
    final crossesMidnight = rawStart > end;

    if (crossesMidnight) {
      final carriedOver =
          nowMinutes != null &&
          nowMinutes < end &&
          scheduledYesterdayIds.contains(habit.id);
      if (carriedOver) {
        entries.add(
          PlanEntry(habit: habit, start: 0, end: end, isCurrent: true),
        );
      } else {
        entries.add(
          PlanEntry(
            habit: habit,
            start: rawStart,
            end: _minutesInDay,
            isCurrent: nowMinutes != null && nowMinutes >= rawStart,
          ),
        );
      }
      continue;
    }

    entries.add(
      PlanEntry(
        habit: habit,
        start: rawStart,
        end: end,
        isCurrent:
            nowMinutes != null && nowMinutes >= rawStart && nowMinutes < end,
      ),
    );
  }

  entries.sort((a, b) {
    if (a.start != b.start) return a.start.compareTo(b.start);
    if (a.end != b.end) return a.end.compareTo(b.end);
    final ca = categoryRank[a.habit.categoryId] ?? 999;
    final cb = categoryRank[b.habit.categoryId] ?? 999;
    if (ca != cb) return ca.compareTo(cb);
    final ao = a.habit.order <= 0 ? 1 << 30 : a.habit.order;
    final bo = b.habit.order <= 0 ? 1 << 30 : b.habit.order;
    if (ao != bo) return ao.compareTo(bo);
    return a.habit.id.compareTo(b.habit.id);
  });

  final sections = <PlanSection>[];
  PlanEntry? previous;
  for (final entry in entries) {
    final startsNewSection =
        previous == null ||
        (entry.start >= previous.end && entry.start > sections.last.start);
    if (startsNewSection) {
      sections.add(PlanSection(start: entry.start, entries: [entry]));
    } else {
      sections.last.entries.add(entry);
    }
    previous = entry;
  }

  return sections;
}
