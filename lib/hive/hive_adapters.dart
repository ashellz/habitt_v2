import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
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
