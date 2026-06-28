import 'package:shared_preferences/shared_preferences.dart';

/// A single deferred habit completion captured from a notification action.
class PendingCompletion {
  final int habitId;
  final DateTime day;

  const PendingCompletion({required this.habitId, required this.day});
}

/// Durable queue for "Complete" presses on habit notifications (Option B).
///
/// The "Complete" action handler runs in a background isolate that has no
/// access to Provider/Hive state, so it cannot complete a habit directly.
/// Instead it appends a lightweight record here; the app drains the queue on
/// start/resume and applies each entry through the real completion logic, so
/// streaks and stats stay correct.
///
/// Entries are stored as `"<habitId>|yyyy-MM-dd"` strings. Enqueue is
/// idempotent per {habitId, day}.
class PendingCompletionQueue {
  PendingCompletionQueue._();

  static const String _prefsKey = 'pending_habit_completions';

  static String _encode(int habitId, DateTime day) =>
      '$habitId|${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static PendingCompletion? _decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    final habitId = int.tryParse(parts[0]);
    final date = DateTime.tryParse(parts[1]);
    if (habitId == null || date == null) return null;
    return PendingCompletion(
      habitId: habitId,
      day: DateTime(date.year, date.month, date.day),
    );
  }

  /// Append a pending completion. Runs from any isolate (background or main).
  /// Idempotent: a duplicate {habitId, day} is ignored.
  static Future<void> enqueue(int habitId, DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    final entry = _encode(habitId, day);
    if (list.contains(entry)) return;
    list.add(entry);
    await prefs.setStringList(_prefsKey, list);
  }

  /// Read pending completions WITHOUT clearing them. Called on the main isolate.
  /// Entries are removed only after they are successfully applied (see [removeAll]),
  /// so a drain that runs before habits finish loading does not lose anything.
  static Future<List<PendingCompletion>> peek() async {
    final prefs = await SharedPreferences.getInstance();
    // Pick up writes made by the background isolate.
    await prefs.reload();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    return list
        .map(_decode)
        .where((e) => e != null)
        .cast<PendingCompletion>()
        .toList();
  }

  /// Remove the given entries from the queue (the ones we successfully processed).
  static Future<void> removeAll(Iterable<PendingCompletion> entries) async {
    if (entries.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    if (list.isEmpty) return;
    final remove = entries.map((e) => _encode(e.habitId, e.day)).toSet();
    final remaining = list.where((e) => !remove.contains(e)).toList();
    if (remaining.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setStringList(_prefsKey, remaining);
    }
  }

  static Future<bool> hasPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    return list.isNotEmpty;
  }
}
