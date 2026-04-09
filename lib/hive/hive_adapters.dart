import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:hive_ce/hive.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([AdapterSpec<Habit>(), AdapterSpec<Day>()])
class HiveAdapters {}

/// TypeAdapter for ScheduleType enum
/// Converts enum to int for storage, and int back to enum on read
class ScheduleTypeAdapter extends TypeAdapter<ScheduleType> {
  @override
  int get typeId => 2; // Unique type ID for ScheduleType

  @override
  ScheduleType read(BinaryReader reader) {
    final index = reader.readByte();
    return ScheduleType.values[index];
  }

  @override
  void write(BinaryWriter writer, ScheduleType obj) {
    writer.writeByte(obj.index);
  }
}

class PremadeHabitTypeAdapter extends TypeAdapter<PremadeHabitType> {
  @override
  int get typeId => 5;

  @override
  PremadeHabitType read(BinaryReader reader) {
    final index = reader.readByte();
    return PremadeHabitType.values[index];
  }

  @override
  void write(BinaryWriter writer, PremadeHabitType obj) {
    writer.writeByte(obj.index);
  }
}

class HabitTrackingTypeAdapter extends TypeAdapter<HabitTrackingType> {
  @override
  int get typeId => 6;

  @override
  HabitTrackingType read(BinaryReader reader) {
    final index = reader.readByte();
    return HabitTrackingType.values[index];
  }

  @override
  void write(BinaryWriter writer, HabitTrackingType obj) {
    writer.writeByte(obj.index);
  }
}

/// Backward-compatibility adapter for older persisted HabitTrackingType values.
/// Some existing boxes contain this enum under typeId 34.
class LegacyHabitTrackingTypeAdapter extends TypeAdapter<HabitTrackingType> {
  @override
  int get typeId => 34;

  @override
  HabitTrackingType read(BinaryReader reader) {
    final index = reader.readByte();
    if (index < 0 || index >= HabitTrackingType.values.length) {
      return HabitTrackingType.amount;
    }
    return HabitTrackingType.values[index];
  }

  @override
  void write(BinaryWriter writer, HabitTrackingType obj) {
    writer.writeByte(obj.index);
  }
}
