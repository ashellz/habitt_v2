import 'package:shared_preferences/shared_preferences.dart';

/// A "Count it" press on the goal check-in notification, waiting to be applied
/// as today's lighter goal.
class PendingDayGoal {
  const PendingDayGoal({
    required this.habitId,
    required this.day,
    required this.goal,
  });

  final int habitId;
  final DateTime day;
  final int goal;
}

/// Durable queue for goal check-in notification actions, like
/// [PendingCompletionQueue]: the action runs in a background isolate without
/// providers, so it only enqueues, and the app applies the entry through
/// `HabitProvider.setTodayGoal` on start/resume. Entries are
/// `"<habitId>|yyyy-MM-dd|<goal>"`, one per habit and day (the latest wins).
class PendingDayGoalQueue {
  PendingDayGoalQueue._();

  static const String _prefsKey = 'pending_day_goals';

  static String _dayString(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static String _encode(PendingDayGoal e) =>
      '${e.habitId}|${_dayString(e.day)}|${e.goal}';

  static PendingDayGoal? _decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    final habitId = int.tryParse(parts[0]);
    final date = DateTime.tryParse(parts[1]);
    final goal = int.tryParse(parts[2]);
    if (habitId == null || date == null || goal == null) return null;
    return PendingDayGoal(
      habitId: habitId,
      day: DateTime(date.year, date.month, date.day),
      goal: goal,
    );
  }

  static Future<void> enqueue(int habitId, DateTime day, int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final prefix = '$habitId|${_dayString(day)}|';
    final list = [
      for (final e in prefs.getStringList(_prefsKey) ?? <String>[])
        if (!e.startsWith(prefix)) e,
      _encode(PendingDayGoal(habitId: habitId, day: day, goal: goal)),
    ];
    await prefs.setStringList(_prefsKey, list);
  }

  static Future<List<PendingDayGoal>> peek() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return [
      for (final raw in prefs.getStringList(_prefsKey) ?? <String>[])
        if (_decode(raw) case final e?) e,
    ];
  }

  static Future<void> removeAll(Iterable<PendingDayGoal> entries) async {
    if (entries.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final remove = entries.map(_encode).toSet();
    final remaining = [
      for (final e in prefs.getStringList(_prefsKey) ?? <String>[])
        if (!remove.contains(e)) e,
    ];
    if (remaining.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setStringList(_prefsKey, remaining);
    }
  }
}
