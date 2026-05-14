// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final typeId = 0;

  @override
  Habit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Habit(
      id: (fields[0] as num).toInt(),
      name: fields[1] as String,
      description: fields[2] == null ? "" : fields[2] as String,
      iconPath: fields[3] as String,
      categoryId: (fields[4] as num).toInt(),
      order: fields[36] == null ? 0 : (fields[36] as num).toInt(),
      amountLabel:
          fields[13] == null
              ? AmountLabelPreset.defaultAmountLabel
              : fields[13] as String,
      tag: fields[5] == null ? "No tag" : fields[5] as String,
      completed: fields[6] == null ? false : fields[6] as bool,
      skipped: fields[14] == null ? false : fields[14] as bool,
      amount: fields[8] == null ? 0 : (fields[8] as num).toInt(),
      amountCompleted: fields[9] == null ? 0 : (fields[9] as num).toInt(),
      duration: fields[10] == null ? 0 : (fields[10] as num).toInt(),
      durationCompleted: fields[11] == null ? 0 : (fields[11] as num).toInt(),
      streak: fields[12] == null ? 0 : (fields[12] as num).toInt(),
      longestStreak: fields[15] == null ? 0 : (fields[15] as num).toInt(),
      optional: fields[25] == null ? false : fields[25] as bool,
      timeIntervalEnabled: fields[17] == null ? false : fields[17] as bool,
      timeIntervalStart: fields[18] == null ? 420 : (fields[18] as num).toInt(),
      timeIntervalEnd: fields[19] == null ? 450 : (fields[19] as num).toInt(),
      scheduleType:
          fields[26] == null ? ScheduleType.daily : fields[26] as ScheduleType,
      weeklyTarget: fields[27] == null ? 1 : (fields[27] as num).toInt(),
      monthlyTarget: fields[28] == null ? 1 : (fields[28] as num).toInt(),
      customIntervalDays: fields[29] == null ? 2 : (fields[29] as num).toInt(),
      selectedDaysAWeek: (fields[30] as List?)?.cast<int>(),
      selectedDaysAMonth: (fields[31] as List?)?.cast<int>(),
      customAppearance: (fields[32] as List?)?.cast<String>(),
      timesCompletedThisWeek:
          fields[33] == null ? 0 : (fields[33] as num).toInt(),
      timesCompletedThisMonth:
          fields[34] == null ? 0 : (fields[34] as num).toInt(),
      createdAt: fields[37] as DateTime?,
      lastCustomUpdate: fields[35] as DateTime?,
      colorName: fields[22] as String?,
      notificationsEnabled: fields[40] == null ? false : fields[40] as bool,
      notificationTimes: (fields[41] as List?)?.cast<HabitNotificationTime>(),
      premadeHabitType: fields[38] as PremadeHabitType?,
      trackingType: fields[39] as HabitTrackingType?,
      isDeleted: fields[24] as bool?,
      timestamps: (fields[23] as Map?)?.cast<String, DateTime>(),
      insightPopstonedUntil: fields[42] as DateTime?,
    )..color = fields[20] as String?;
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(40)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconPath)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.tag)
      ..writeByte(6)
      ..write(obj.completed)
      ..writeByte(8)
      ..write(obj.amount)
      ..writeByte(9)
      ..write(obj.amountCompleted)
      ..writeByte(10)
      ..write(obj.duration)
      ..writeByte(11)
      ..write(obj.durationCompleted)
      ..writeByte(12)
      ..write(obj.streak)
      ..writeByte(13)
      ..write(obj.amountLabel)
      ..writeByte(14)
      ..write(obj.skipped)
      ..writeByte(15)
      ..write(obj.longestStreak)
      ..writeByte(17)
      ..write(obj.timeIntervalEnabled)
      ..writeByte(18)
      ..write(obj.timeIntervalStart)
      ..writeByte(19)
      ..write(obj.timeIntervalEnd)
      ..writeByte(20)
      ..write(obj.color)
      ..writeByte(22)
      ..write(obj.colorName)
      ..writeByte(23)
      ..write(obj.timestamps)
      ..writeByte(24)
      ..write(obj.isDeleted)
      ..writeByte(25)
      ..write(obj.optional)
      ..writeByte(26)
      ..write(obj.scheduleType)
      ..writeByte(27)
      ..write(obj.weeklyTarget)
      ..writeByte(28)
      ..write(obj.monthlyTarget)
      ..writeByte(29)
      ..write(obj.customIntervalDays)
      ..writeByte(30)
      ..write(obj.selectedDaysAWeek)
      ..writeByte(31)
      ..write(obj.selectedDaysAMonth)
      ..writeByte(32)
      ..write(obj.customAppearance)
      ..writeByte(33)
      ..write(obj.timesCompletedThisWeek)
      ..writeByte(34)
      ..write(obj.timesCompletedThisMonth)
      ..writeByte(35)
      ..write(obj.lastCustomUpdate)
      ..writeByte(36)
      ..write(obj.order)
      ..writeByte(37)
      ..write(obj.createdAt)
      ..writeByte(38)
      ..write(obj.premadeHabitType)
      ..writeByte(39)
      ..write(obj.trackingType)
      ..writeByte(40)
      ..write(obj.notificationsEnabled)
      ..writeByte(41)
      ..write(obj.notificationTimes)
      ..writeByte(42)
      ..write(obj.insightPopstonedUntil);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DayAdapter extends TypeAdapter<Day> {
  @override
  final typeId = 1;

  @override
  Day read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Day(
      date: fields[0] as DateTime,
      habits: (fields[1] as List).cast<Habit>(),
      timestamp: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Day obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.habits)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
