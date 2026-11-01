import 'package:flutter/foundation.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/util/date_key.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the `yyyy-MM-dd` dates a custom-interval ("every N days") habit
/// appears on: [anchor]'s day, then every [intervalDays] days for [spanDays]
/// days.
///
/// Uses calendar arithmetic (`DateTime(y, m, d + i)`), never
/// `anchor.add(Duration(days: i))`: a Duration is i * 24 h, so once the range
/// crosses a 25-hour DST fall-back day it lands on 23:00 of the previous day
/// and every later key comes out one day early.
List<String> buildCustomAppearance({
  required DateTime anchor,
  required int intervalDays,
  int spanDays = 365,
}) {
  final step = intervalDays.clamp(1, 365);
  final output = <String>[];
  for (var i = 0; i < spanDays; i += step) {
    output.add(dateKey(DateTime(anchor.year, anchor.month, anchor.day + i)));
  }
  return output;
}

/// How many days ahead the habit sheets fill a new/edited custom schedule.
/// HabitProvider extends the list on demand once it runs out.
const int kNewCustomAppearanceSpanDays = 180;

/// Custom-appearance list for a habit created or edited now, anchored on
/// today's local date.
List<String> buildCustomAppearanceFromToday(int intervalDays) {
  return buildCustomAppearance(
    anchor: DateTime.now(),
    intervalDays: intervalDays,
    spanDays: kNewCustomAppearanceSpanDays,
  );
}

/// Extends a stored custom-appearance list so it covers [through], plus
/// [aheadDays] of headroom.
///
/// New dates continue the existing grid from the last stored date (last + N,
/// last + 2N, ...), so extending never moves the habit's schedule. Only when
/// there is no usable last date does it start a fresh grid at
/// [fallbackAnchor]. Entries before [keepFrom] are dropped so the list (which
/// is also copied into every day snapshot) doesn't grow forever.
List<String> extendCustomAppearance({
  required List<String> dates,
  required int intervalDays,
  required DateTime through,
  required DateTime fallbackAnchor,
  required DateTime keepFrom,
  int aheadDays = 365,
}) {
  final last = dates.isEmpty ? null : DateTime.tryParse(dates.last);
  final start = last ?? fallbackAnchor;
  final spanDays = calendarDaysBetween(start, through) + aheadDays;
  final extension = buildCustomAppearance(
    anchor: start,
    intervalDays: intervalDays,
    spanDays: spanDays < 1 ? 1 : spanDays,
  );

  final keepKey = dateKey(keepFrom);
  final merged =
      last == null
          ? extension
          // extension.first is the last stored date itself
          : [...dates, ...extension.skip(1)];
  return merged.where((d) => d.compareTo(keepKey) >= 0).toList();
}

// Day number of a calendar date, computed in UTC so DST can't skew the gap.
int _dayNumber(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

DateTime _fromDayNumber(int n) {
  final utc = DateTime.fromMillisecondsSinceEpoch(
    n * Duration.millisecondsPerDay,
    isUtc: true,
  );
  return DateTime(utc.year, utc.month, utc.day);
}

/// Length in hours of local calendar day [day]: 25 on a DST fall-back day,
/// 23 on a spring-forward day, 24 otherwise.
int localDayHours(DateTime day) {
  return DateTime(
    day.year,
    day.month,
    day.day + 1,
  ).difference(DateTime(day.year, day.month, day.day)).inHours;
}

/// Repairs a custom-appearance list produced by the old `Duration(days: i)`
/// builders, or returns null when there is nothing to repair.
///
/// The bug shows up as a gap of `intervalDays - 1` between two consecutive
/// dates that straddle a local DST fall-back day; every date after it is one
/// day early. If the same list later crosses a spring-forward day the keys
/// snap back onto the grid, which shows up as a gap of `intervalDays + 1`.
/// Any other irregular gap (e.g. a late-completion reschedule that restarted
/// the grid) is treated as a fresh, correct anchor.
///
/// Only dates on or after [today] are moved. Past dates are left as stored:
/// day snapshots carry their own copy of the list for streaks, and the live
/// list's past entries should keep matching what the user actually saw.
List<String>? repairDstShiftedCustomAppearance({
  required List<String> dates,
  required int intervalDays,
  required DateTime today,
  @visibleForTesting int Function(DateTime day) dayHours = localDayHours,
}) {
  if (dates.length < 2) return null;
  final step = intervalDays.clamp(1, 365);

  final stored = <int>[];
  for (final raw in dates) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null; // unknown format, leave it alone
    stored.add(_dayNumber(parsed));
  }

  bool hasDayOfLength(int from, int to, int hours) {
    for (var n = from; n <= to; n++) {
      if (dayHours(_fromDayNumber(n)) == hours) return true;
    }
    return false;
  }

  final todayNumber = _dayNumber(today);
  var offset = 0;
  var shifted = false;
  final repaired = <int>{};

  for (var i = 0; i < stored.length; i++) {
    if (i > 0) {
      final prev = stored[i - 1];
      final cur = stored[i];
      final gap = cur - prev;
      if (gap == step) {
        // still on the same grid, keep the current offset
      } else if (gap == step - 1 && hasDayOfLength(prev, cur, 25)) {
        offset += 1;
        shifted = true;
      } else if (gap == step + 1 &&
          offset > 0 &&
          hasDayOfLength(prev, cur, 23)) {
        offset -= 1;
      } else {
        offset = 0;
      }
    }

    final value = stored[i];
    if (value < todayNumber) repaired.add(value);
    final corrected = value + offset;
    if (corrected >= todayNumber) repaired.add(corrected);
  }

  if (!shifted) return null;

  final output = (repaired.toList()..sort())
      .map((n) => dateKey(_fromDayNumber(n)))
      .toList(growable: true);
  if (output.length == dates.length) {
    var same = true;
    for (var i = 0; i < output.length; i++) {
      if (output[i] != dates[i]) {
        same = false;
        break;
      }
    }
    if (same) return null;
  }
  return output;
}

// shared prefs key that tells the app the DST-shifted custom schedules have
// been repaired
const String customAppearanceDstRepairedKey = 'customAppearanceDstRepaired_v1';

/// One-time repair of custom-interval schedules shifted a day early by the old
/// DST-unsafe builders (see [repairDstShiftedCustomAppearance]). Only live
/// habits are touched; day snapshots in the `days` box keep their own copy.
Future<void> migrateDstShiftedCustomAppearance({
  required Box<Habit> habitBox,
  required SharedPreferences prefs,
  DateTime? today,
  @visibleForTesting int Function(DateTime day) dayHours = localDayHours,
}) async {
  if (prefs.getBool(customAppearanceDstRepairedKey) ?? false) {
    return;
  }

  final now = DateTime.now();
  final day = today ?? now;
  final updates = <dynamic, Habit>{};
  for (final key in habitBox.keys) {
    final habit = habitBox.get(key);
    if (habit == null) continue;
    if (habit.scheduleType != ScheduleType.custom) continue;
    final repaired = repairDstShiftedCustomAppearance(
      dates: habit.customAppearance,
      intervalDays: habit.customIntervalDays,
      today: day,
      dayHours: dayHours,
    );
    if (repaired == null) continue;
    habit.customAppearance = repaired;
    habit.timestamps['customAppearance'] = now.toUtc();
    updates[key] = habit;
  }
  if (updates.isNotEmpty) {
    await habitBox.putAll(updates);
  }

  await prefs.setBool(customAppearanceDstRepairedKey, true);
}
