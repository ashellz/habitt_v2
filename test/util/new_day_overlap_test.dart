import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/hive/hive_adapters.dart';
import 'package:habitt/hive/hive_registrar.g.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/date_key.dart';
import 'package:habitt/util/update_last_date.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime n(DateTime d) => DateTime(d.year, d.month, d.day);
String k(DateTime d) => n(d).toIso8601String().split('T').first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var registered = false;

  Future<void> scenario(String label, {required bool concurrent}) async {
    final dir = await Directory.systemTemp.createTemp('race');
    Hive.init(dir.path);
    if (!registered) {
      registered = true;
      Hive.registerAdapters();
      Hive.registerAdapter(ScheduleTypeAdapter());
      Hive.registerAdapter(PremadeHabitTypeAdapter());
      Hive.registerAdapter(HabitTrackingTypeAdapter());
      Hive.registerAdapter(HabitNotificationTimeAdapter());
      Hive.registerAdapter(LegacyHabitTrackingTypeAdapter());
    }
    final habitBox = await Hive.openBox<Habit>('habits');
    final daysBox = await Hive.openBox<Day>('days');
    final today = n(DateTime.now());
    final yesterday = addCalendarDays(today, -1);
    SharedPreferences.setMockInitialValues({
      'lastNotificationSyncDate': k(today),
      'daySnapshotsSanitized_v1': true,
      'lastOpenedDate': yesterday.add(const Duration(hours: 20)).toString(),
    });
    final daily = Habit(id: 1, name: 'daily', iconPath: '', categoryId: 1,
        createdAt: addCalendarDays(today, -60), completed: true);
    final daily2 = Habit(id: 2, name: 'daily2', iconPath: '', categoryId: 1,
        createdAt: addCalendarDays(today, -60), completed: true);
    await habitBox.add(daily); await habitBox.add(daily2);
    for (var i = 10; i >= 1; i--) {
      final d = addCalendarDays(today, -i);
      await daysBox.put(k(d), Day(date: d, habits: [daily.copy()..completed = true, daily2.copy()..completed = true], timestamp: DateTime.now()));
    }
    final p = HabitProvider();
    final dl = DateTime.now().add(const Duration(seconds: 10));
    while (!p.isInitialized) {
      if (DateTime.now().isAfter(dl)) fail('init');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final prefs = await SharedPreferences.getInstance();
    final sp = StateProvider(prefs);
    final st = StatsProvider(prefs: prefs);
    if (concurrent) {
      // startup call + a resume event while the first is still running
      final a = updateLastOpenedDate(p, sp, st);
      await Future<void>.delayed(Duration.zero);
      final b = updateLastOpenedDate(p, sp, st);
      await Future.wait([a, b]);
    } else {
      await updateLastOpenedDate(p, sp, st);
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    final y = daysBox.get(k(yesterday));
    expect(y?.habits.length, 2, reason: label);
    expect(y?.habits.where((h) => h.completed).length, 2, reason: label);
    await Hive.close();
  }

  test('a single check keeps yesterday progress', () => scenario('single call', concurrent: false));
  test('overlapping checks keep yesterday progress', () => scenario('two overlapping calls', concurrent: true));
}
