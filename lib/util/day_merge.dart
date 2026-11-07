import 'package:flutter/foundation.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';

/// Merges another device's snapshot of a day into this device's copy of it.
///
/// Every habit copy is merged on its own ([Habit.merge]: the completion tuple
/// modified most recently wins, a tie keeps the local one), whatever the two
/// days' own timestamps say. A day's timestamp moves on any write to it, so
/// it can't say whose copy of one habit is newer. Skipping a whole incoming
/// day because the local one was touched later dropped the other device's
/// newer completions on it for good (both devices then held the same day
/// timestamp and kept skipping each other's copy).
///
/// [countingForDay] collapses the merged union back to the habits that count
/// on that day (see `HabitProvider.habitsCountingForDay`).
///
/// Returns the day to store, or null when the merge leaves the local day's
/// habits as they are (nothing to write).
Day? mergeDaySnapshot({
  required Day? local,
  required Day incoming,
  required List<Habit> Function(List<Habit> habits) countingForDay,
  String? debugLabel,
}) {
  final localById = <int, Habit>{};
  if (local != null) {
    for (final h in local.habits) {
      if (h.isDeleted ?? false) continue;
      localById[h.id] = h;
    }
  }

  final merged = <Habit>[];
  for (final incomingHabit in incoming.habits) {
    final localHabit = localById.remove(incomingHabit.id);
    if (localHabit != null) {
      final result = localHabit.merge(incomingHabit);
      if (debugLabel != null && result.completed != localHabit.completed) {
        debugPrint(
          '[SYNC]   day $debugLabel habit id=${incomingHabit.id} "${incomingHabit.name}": '
          'completed ${localHabit.completed}→${result.completed} '
          '(local completedTs=${localHabit.timestamps["completed"]}, '
          'incoming completedTs=${incomingHabit.timestamps["completed"]})',
        );
      }
      merged.add(result);
    } else {
      if (incomingHabit.isDeleted ?? false) continue;
      merged.add(incomingHabit);
    }
  }
  merged.addAll(localById.values);

  final habits = [for (final h in countingForDay(merged)) h.forDay()];

  if (local != null && sameDayHabits(local.habits, habits)) return null;

  final localTs = local?.timestamp;
  final incomingTs = incoming.timestamp;
  final mergedTs =
      (localTs != null && incomingTs != null)
          ? (incomingTs.isAfter(localTs) ? incomingTs : localTs)
          : (localTs ?? incomingTs);

  return Day(date: incoming.date, habits: habits, timestamp: mergedTs);
}

/// Whether two day snapshots hold the same habit copies, in any order.
/// Compares what a day snapshot stores ([Habit.toMap] with `forDay`).
bool sameDayHabits(List<Habit> a, List<Habit> b) {
  if (a.length != b.length) return false;
  final byId = {for (final h in a) h.id: h.toMap(forDay: true)};
  if (byId.length != a.length) return false;
  for (final h in b) {
    final other = byId[h.id];
    if (other == null || !_deepEquals(other, h.toMap(forDay: true))) {
      return false;
    }
  }
  return true;
}

bool _deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
