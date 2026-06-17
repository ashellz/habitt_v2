import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/util/amount_label_preset.dart';
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
/// This adapter is intentionally `dynamic` so Hive can keep the canonical
/// typed adapter (typeId 6) for writes while still decoding legacy typeId 34.
class LegacyHabitTrackingTypeAdapter extends TypeAdapter<dynamic> {
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
  void write(BinaryWriter writer, dynamic obj) {
    final value = obj is HabitTrackingType ? obj : HabitTrackingType.amount;
    writer.writeByte(value.index);
  }
}

class HabitNotificationTimeAdapter extends TypeAdapter<HabitNotificationTime> {
  @override
  int get typeId => 7;

  @override
  HabitNotificationTime read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return HabitNotificationTime(
      id: (fields[0] as num?)?.toInt() ?? DateTime.now().microsecondsSinceEpoch,
      minutesOfDay: ((fields[1] as num?)?.toInt() ?? (8 * 60)).clamp(
        0,
        (24 * 60) - 1,
      ),
      // Legacy records (written before per-notification weekdays) have no
      // field 2; they decode to an empty list = "follow habit schedule".
      days:
          (fields[2] as List?)
              ?.map((e) => (e is num) ? e.toInt() : null)
              .whereType<int>()
              .where((d) => d >= 1 && d <= 7)
              .toList() ??
          const <int>[],
    );
  }

  @override
  void write(BinaryWriter writer, HabitNotificationTime obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.minutesOfDay)
      ..writeByte(2)
      ..write(obj.days);
  }
}
