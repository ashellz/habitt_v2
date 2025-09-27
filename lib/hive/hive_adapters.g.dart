// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class HabitAdapter extends TypeAdapter<Habit> {
  @override
  final int typeId = 0;

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
      amountLabel: fields[13] == null ? "times" : fields[13] as String,
      tag: fields[5] == null ? "No tag" : fields[5] as String,
      completed: fields[6] == null ? false : fields[6] as bool,
      skipped: fields[14] == null ? false : fields[14] as bool,
      amount: fields[8] == null ? 0 : (fields[8] as num).toInt(),
      amountCompleted: fields[9] == null ? 0 : (fields[9] as num).toInt(),
      duration: fields[10] == null ? 0 : (fields[10] as num).toInt(),
      durationCompleted: fields[11] == null ? 0 : (fields[11] as num).toInt(),
      streak: fields[12] == null ? 0 : (fields[12] as num).toInt(),
      longestStreak: fields[15] == null ? 0 : (fields[15] as num).toInt(),
      additional: fields[16] == null ? false : fields[16] as bool,
      timeIntervalEnabled: fields[17] == null ? false : fields[17] as bool,
      timeIntervalStart: fields[18] == null ? 0 : (fields[18] as num).toInt(),
      timeIntervalEnd: fields[19] == null ? 0 : (fields[19] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Habit obj) {
    writer
      ..writeByte(19)
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
      ..writeByte(16)
      ..write(obj.additional)
      ..writeByte(17)
      ..write(obj.timeIntervalEnabled)
      ..writeByte(18)
      ..write(obj.timeIntervalStart)
      ..writeByte(19)
      ..write(obj.timeIntervalEnd);
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
  final int typeId = 1;

  @override
  Day read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Day(
      date: fields[0] as DateTime,
      habits: (fields[1] as List).cast<Habit>(),
    );
  }

  @override
  void write(BinaryWriter writer, Day obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.habits);
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
