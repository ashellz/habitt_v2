
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:hive_ce/hive.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([AdapterSpec<Habit>(), AdapterSpec<Day>()])
class HiveAdapters {}
