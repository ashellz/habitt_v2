class HabitNotificationTime {
  final int id;
  int minutesOfDay;

  // 1 = mon, 7 = sun. emtpy = follow habit schedule
  List<int> days;

  HabitNotificationTime({
    required this.id,
    required this.minutesOfDay,
    List<int>? days,
  }) : days = days ?? [];

  bool firesOnWeekday(int weekday) => days.isEmpty || days.contains(weekday);

  /// Slots in [previous] that no longer exist in [current] (matched by id).
  /// Their already-scheduled notifications are no longer reachable through the
  /// habit's current slots, so they have to be cancelled explicitly.
  static List<HabitNotificationTime> removedSlots(
    Iterable<HabitNotificationTime> previous,
    Iterable<HabitNotificationTime> current,
  ) {
    final currentIds = current.map((slot) => slot.id).toSet();
    return previous.where((slot) => !currentIds.contains(slot.id)).toList();
  }

  HabitNotificationTime copy() {
    return HabitNotificationTime(
      id: id,
      minutesOfDay: minutesOfDay,
      days: List<int>.from(days),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'minutesOfDay': minutesOfDay, 'days': days};
  }

  factory HabitNotificationTime.fromMap(Map<String, dynamic> map) {
    final parsedId =
        (map['id'] as num?)?.toInt() ?? DateTime.now().microsecondsSinceEpoch;
    final parsedMinutes = (map['minutesOfDay'] as num?)?.toInt() ?? 8 * 60;

    return HabitNotificationTime(
      id: parsedId,
      minutesOfDay: parsedMinutes.clamp(0, (24 * 60) - 1),
      days: _parseDays(map['days']),
    );
  }

  static List<int> _parseDays(dynamic value) {
    if (value is! List) return [];
    return value
        .map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }
}
