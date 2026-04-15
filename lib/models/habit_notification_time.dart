class HabitNotificationTime {
  final int id;
  int minutesOfDay;

  HabitNotificationTime({required this.id, required this.minutesOfDay});

  HabitNotificationTime copy() {
    return HabitNotificationTime(id: id, minutesOfDay: minutesOfDay);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'minutesOfDay': minutesOfDay};
  }

  factory HabitNotificationTime.fromMap(Map<String, dynamic> map) {
    final parsedId =
        (map['id'] as num?)?.toInt() ?? DateTime.now().microsecondsSinceEpoch;
    final parsedMinutes = (map['minutesOfDay'] as num?)?.toInt() ?? 8 * 60;

    return HabitNotificationTime(
      id: parsedId,
      minutesOfDay: parsedMinutes.clamp(0, (24 * 60) - 1),
    );
  }
}
