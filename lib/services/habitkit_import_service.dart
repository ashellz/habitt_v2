import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:hive_ce/hive.dart';
import 'package:provider/provider.dart';

class HabitKitImportResult {
  HabitKitImportResult({
    required this.habits,
    required this.days,
    required this.earliestDate,
  });

  final List<Habit> habits;
  final List<Day> days;
  final DateTime? earliestDate;
}

class HabitKitImportService {
  // ─── Public API ───────────────────────────────────────────────────────────

  static HabitKitImportResult parse(String jsonString) {
    final root = jsonDecode(jsonString) as Map<String, dynamic>;
    final habitsList = (root['habits'] as List<dynamic>?) ?? [];
    final completionsList = (root['completions'] as List<dynamic>?) ?? [];

    // Assign stable int ids to each imported habit (UUID → int).
    int idCounter = DateTime.now().microsecondsSinceEpoch;
    final uuidToId = <String, int>{};
    final habitDefs = <Map<String, dynamic>>[];

    for (final raw in habitsList) {
      final h = raw as Map<String, dynamic>;
      final uuid = h['id'] as String;
      uuidToId[uuid] = idCounter++;
      habitDefs.add(h);
    }

    // Build the master habit list (for habitBox on overwrite; template for days).
    final habits =
        habitDefs
            .map((h) => _buildHabit(h, uuidToId[h['id'] as String]!))
            .toList();

    // Group completions: dateKey → { uuid → completed }
    final byDate = <String, Map<String, bool>>{};
    for (final raw in completionsList) {
      final c = raw as Map<String, dynamic>;
      final uuid = c['habitId'] as String;
      final offset = (c['timezoneOffsetInMinutes'] as num).toInt();
      final localDate = _resolveLocalDate(c['date'] as String, offset);
      final key = _dayKey(localDate);
      byDate.putIfAbsent(key, () => {});
      final done = ((c['amountOfCompletions'] as num?) ?? 0) > 0;
      // Only upgrade false→true; never downgrade a true entry.
      if (done) byDate[key]![uuid] = true;
      byDate[key]!.putIfAbsent(uuid, () => false);
    }

    // Build Day snapshots — every day includes all habits that existed by then.
    DateTime? earliestDate;
    final days = <Day>[];

    for (final entry in byDate.entries) {
      final date = DateTime.parse(entry.key);
      if (earliestDate == null || date.isBefore(earliestDate)) {
        earliestDate = date;
      }

      final dayHabits = <Habit>[];
      for (final def in habitDefs) {
        final createdAt = DateTime.parse(def['createdAt'] as String).toUtc();
        if (date.isBefore(
          DateTime(createdAt.year, createdAt.month, createdAt.day),
        ))
          continue;

        final uuid = def['id'] as String;
        final id = uuidToId[uuid]!;
        final completed = entry.value[uuid] ?? false;
        dayHabits.add(_buildHabit(def, id, completed: completed));
      }

      days.add(
        Day(date: date, habits: dayHabits, timestamp: DateTime.now().toUtc()),
      );
    }

    return HabitKitImportResult(
      habits: habits,
      days: days,
      earliestDate: earliestDate,
    );
  }

  /// Wipes local data and replaces it entirely with the HabitKit import.
  static Future<bool> overwrite(
    BuildContext context,
    HabitKitImportResult result,
  ) async {
    try {
      final habitsBox = Hive.box<Habit>('habits');
      final daysBox = Hive.box<Day>('days');

      await habitsBox.clear();
      await daysBox.clear();

      for (final habit in result.habits) {
        await habitsBox.add(habit);
      }
      for (final day in result.days) {
        await daysBox.put(_dayKey(day.date), day);
      }

      if (context.mounted && result.earliestDate != null) {
        await context.read<HabitProvider>().importDateJoined(
          result.earliestDate!,
        );
      }
      if (context.mounted) await context.read<HabitProvider>().init();

      return true;
    } catch (e, st) {
      debugPrint('HabitKit overwrite failed: $e\n$st');
      return false;
    }
  }

  /// Merges HabitKit data into existing local data.
  /// Habits with matching names (case-insensitive) share history; new ones are added.
  static Future<bool> merge(
    BuildContext context,
    HabitKitImportResult result,
  ) async {
    try {
      final habitsBox = Hive.box<Habit>('habits');
      final daysBox = Hive.box<Day>('days');

      // Map existing habits by lower-case name for matching.
      final existingByName = <String, Habit>{};
      for (final h in habitsBox.values) {
        if (h.isDeleted != true) existingByName[h.name.toLowerCase()] = h;
      }

      // Decide: matched existing id or add new habit.
      final idRemap = <int, int>{}; // importedId → finalId
      for (final imported in result.habits) {
        final match = existingByName[imported.name.toLowerCase()];
        if (match != null) {
          idRemap[imported.id] = match.id;
        } else {
          await habitsBox.add(imported);
          idRemap[imported.id] = imported.id;
        }
      }

      // Merge days.
      for (final importedDay in result.days) {
        final key = _dayKey(importedDay.date);
        final existingDay = daysBox.get(key);

        if (existingDay == null) {
          await daysBox.put(key, importedDay);
          continue;
        }

        // Index existing day habits by name for O(1) lookup.
        final nameToIdx = <String, int>{};
        for (var i = 0; i < existingDay.habits.length; i++) {
          nameToIdx[existingDay.habits[i].name.toLowerCase()] = i;
        }

        final merged = List<Habit>.from(existingDay.habits);
        for (final ih in importedDay.habits) {
          final idx = nameToIdx[ih.name.toLowerCase()];
          if (idx != null) {
            // Only upgrade to completed — never strip an existing completion.
            if (ih.completed && !merged[idx].completed) {
              merged[idx] = merged[idx].copy()..completed = true;
            }
          } else {
            merged.add(ih);
          }
        }

        await daysBox.put(
          key,
          Day(
            date: existingDay.date,
            habits: merged,
            timestamp: DateTime.now().toUtc(),
          ),
        );
      }

      if (context.mounted && result.earliestDate != null) {
        await context.read<HabitProvider>().importDateJoined(
          result.earliestDate!,
        );
      }
      if (context.mounted) await context.read<HabitProvider>().init();

      return true;
    } catch (e, st) {
      debugPrint('HabitKit merge failed: $e\n$st');
      return false;
    }
  }

  static Habit _buildHabit(
    Map<String, dynamic> def,
    int id, {
    bool completed = false,
  }) {
    return Habit(
      id: id,
      name: def['name'] as String,
      description: (def['description'] as String?) ?? '',
      iconPath: _mapIcon((def['icon'] as String?) ?? ''),
      categoryId: 1,
      order: (def['orderIndex'] as num?)?.toInt() ?? 0,
      completed: completed,
      createdAt: DateTime.parse(def['createdAt'] as String).toUtc(),
      colorName: _mapColor((def['color'] as String?) ?? ''),
      isDeleted: (def['archived'] as bool?) ?? false,
      premadeHabitType: _inferPremadeType(def['name'] as String),
    );
  }

  // Assiging premade habit types based on keywords in the habit name
  static PremadeHabitType? _inferPremadeType(String name) {
    final lower = name.toLowerCase();
    for (final entry in _premadeKeywords) {
      for (final kw in entry.value) {
        if (RegExp('\\b${RegExp.escape(kw)}\\b').hasMatch(lower)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  static const _premadeKeywords = <MapEntry<PremadeHabitType, List<String>>>[
    MapEntry(PremadeHabitType.gym, [
      'gym',
      'workout',
      'work out',
      'work-out',
      'exercise',
      'fitness',
      'weights',
      'weight lifting',
      'weightlifting',
      'lifting',
      'lift weights',
      'cardio',
      'crossfit',
      'squat',
      'squats',
      'bench',
      'deadlift',
      'push up',
      'push-up',
      'pushup',
      'push ups',
      'pushups',
      'pull up',
      'pull-up',
      'pullup',
      'pull ups',
      'pullups',
      'sit up',
      'sit-up',
      'situp',
      'abs',
      'core',
      'hiit',
      'training',
      'dumbbell',
      'barbell',
      'yoga',
      'pilates',
      'stretch',
      'stretching',
      'sport',
      'sports',
      'activity',
    ]),
    MapEntry(PremadeHabitType.running, [
      'run',
      'runs',
      'running',
      'jog',
      'jogs',
      'jogging',
      'sprint',
      'sprints',
      'marathon',
      '5k',
      '10k',
    ]),
    MapEntry(PremadeHabitType.walk, [
      'walk',
      'walks',
      'walking',
      'steps',
      'step count',
      'stroll',
      'hike',
      'hikes',
      'hiking',
    ]),
    MapEntry(PremadeHabitType.read, [
      'read',
      'reads',
      'reading',
      'book',
      'books',
      'novel',
      'kindle',
    ]),
    MapEntry(PremadeHabitType.brushTeeth, [
      'brush teeth',
      'brush my teeth',
      'teeth',
      'floss',
      'flossing',
      'toothbrush',
      'dental',
      'oral hygiene',
    ]),
    MapEntry(PremadeHabitType.skinCare, [
      'skincare',
      'skin care',
      'skin',
      'moisturize',
      'moisturise',
      'moisturizer',
      'moisturiser',
      'face wash',
      'wash face',
      'serum',
      'cleanser',
      'cleanse',
      'facial',
    ]),
    MapEntry(PremadeHabitType.shower, ['shower', 'bath', 'bathe', 'bathing']),
    MapEntry(PremadeHabitType.goToBedEarly, [
      'go to bed',
      'bedtime',
      'bed early',
      'early bed',
      'sleep early',
      'early night',
      'lights out',
      'bed',
      'sleep',
    ]),
    MapEntry(PremadeHabitType.wakeUpEarly, [
      'wake up',
      'wake up early',
      'wakeup',
      'wake',
      'get up early',
      'rise early',
      'early bird',
      'morning alarm',
    ]),
    MapEntry(PremadeHabitType.praying, [
      'pray',
      'prayer',
      'prayers',
      'praying',
      'salah',
      'salat',
      'namaz',
      'namaaz',
      'dua',
      'quran',
      'bible',
      'scripture',
      'worship',
      'devotion',
      'church',
      'mosque',
    ]),
    MapEntry(PremadeHabitType.drinkWater, [
      'water',
      'drink water',
      'hydrate',
      'hydration',
      'stay hydrated',
      'h2o',
    ]),
    MapEntry(PremadeHabitType.medications, [
      'medication',
      'medications',
      'medicine',
      'meds',
      'pill',
      'pills',
      'vitamin',
      'vitamins',
      'supplement',
      'supplements',
      'tablet',
      'tablets',
    ]),
    MapEntry(PremadeHabitType.nutrition, [
      'nutrition',
      'diet',
      'healthy eating',
      'eat healthy',
      'eat clean',
      'meal prep',
      'meal',
      'meals',
      'vegetable',
      'vegetables',
      'veggies',
      'fruit',
      'fruits',
      'salad',
      'calories',
      'protein',
      'no junk',
      'no sugar',
    ]),
    MapEntry(PremadeHabitType.research, [
      'research',
      'thesis',
      'dissertation',
      'experiment',
      'experiments',
      'literature review',
    ]),
    MapEntry(PremadeHabitType.studying, [
      'study',
      'studying',
      'studies',
      'homework',
      'revise',
      'revision',
      'learn',
      'learning',
      'lecture',
      'lectures',
      'class',
      'classes',
      'exam',
      'exams',
      'school',
      'course',
      'quiz',
    ]),
    MapEntry(PremadeHabitType.productivitySession, [
      'productivity',
      'deep work',
      'deep focus',
      'focus session',
      'focus',
      'pomodoro',
    ]),
    MapEntry(PremadeHabitType.work, [
      'work',
      'working',
      'job',
      'office',
      'career',
    ]),
  ];

  static DateTime _resolveLocalDate(String utcIso, int offsetMinutes) {
    final utc = DateTime.parse(utcIso).toUtc();
    final local = utc.add(Duration(minutes: offsetMinutes));
    return DateTime(local.year, local.month, local.day);
  }

  static String _dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _mapIcon(String icon) => _iconMap[icon] ?? '📌';

  static String? _mapColor(String color) => _colorMap[color];

  static const _iconMap = <String, String>{
    'bike': '🚴',
    'dumbbell': '🏋️',
    'book': '📚',
    'book_open': '📖',
    'alert_octagon': '⚠️',
    'bed': '🛏️',
    'showerhead': '🚿',
    'run': '🏃',
    'running': '🏃',
    'footprints': '🚶',
    'walk': '🚶',
    'coffee': '☕',
    'heart': '❤️',
    'heart_pulse': '💓',
    'droplets': '💧',
    'water': '💧',
    'apple': '🍎',
    'salad': '🥗',
    'utensils': '🍽️',
    'music': '🎵',
    'headphones': '🎧',
    'phone': '📱',
    'laptop': '💻',
    'pencil': '✏️',
    'pen': '🖊️',
    'notebook': '📓',
    'moon': '🌙',
    'sun': '☀️',
    'flame': '🔥',
    'star': '⭐',
    'check': '✅',
    'check_circle': '✅',
    'smile': '😊',
    'pill': '💊',
    'leaf': '🌿',
    'tree': '🌳',
    'flower': '🌸',
    'target': '🎯',
    'trophy': '🏆',
    'camera': '📸',
    'guitar': '🎸',
    'football': '⚽',
    'basketball': '🏀',
    'swimming': '🏊',
    'yoga': '🧘',
    'meditation': '🧘',
    'clock': '⏰',
    'calendar': '📅',
    'briefcase': '💼',
    'chart': '📊',
    'paint': '🎨',
    'scissors': '✂️',
    'dog': '🐶',
    'cat': '🐱',
    'zap': '⚡',
    'shield': '🛡️',
    'brain': '🧠',
    'eye': '👁️',
    'hand': '🤚',
    'home': '🏠',
    'car': '🚗',
    'bicycle': '🚲',
    'mountain': '⛰️',
    'waves': '🌊',
    'wind': '💨',
    'cloud': '☁️',
    'snowflake': '❄️',
    'sprout': '🌱',
    'grape': '🍇',
    'banana': '🍌',
    'carrot': '🥕',
    'egg': '🥚',
  };

  static const _colorMap = <String, String?>{
    'teal': 'teal',
    'purple': 'purple',
    'red': 'red',
    'lime': 'green',
    'amber': 'orange',
    'stone': 'brown',
    'blue': 'blue',
    'cyan': 'cyan',
    'pink': 'pink',
    'yellow': 'yellow',
    'green': 'green',
    'orange': 'orange',
    'indigo': 'blue',
    'violet': 'purple',
    'rose': 'pink',
    'emerald': 'green',
    'sky': 'lightBlue',
    'fuchsia': 'pink',
    'slate': 'brown',
    'zinc': 'brown',
    'neutral': 'brown',
    'gray': 'brown',
    'grey': 'brown',
  };
}
