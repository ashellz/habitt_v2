import 'dart:ui';

import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/color_service.dart';
import 'package:habitt/util/color_converting.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/select_habit_time_body.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:tinycolor2/tinycolor2.dart';

class Habit extends HiveObject {
  final int id;
  String name;
  String description;
  String iconPath;
  int categoryId; // Any time, Morning, Afternoon, Evening
  String tag; // Custom tags
  bool completed;
  bool skipped;
  String amountLabel;
  int amount; // Number of times to do
  int amountCompleted; // Number of times completed
  int duration; // How long to do
  int durationCompleted; // How long has been done
  int streak;
  int longestStreak;
  bool additional;
  bool timeIntervalEnabled;
  int timeIntervalStart; // In minutes
  int timeIntervalEnd; // In minutes
  String? colorName; // Maps to theme-aware palette
  String? color;
  bool? isDeleted;
  Map<String, DateTime> timestamps;

  Habit({
    required this.id,
    required this.name,
    this.description = "",
    required this.iconPath,
    required this.categoryId,
    this.amountLabel = "times",
    this.tag = "No tag",
    this.completed = false,
    this.skipped = false,
    this.amount = 0,
    this.amountCompleted = 0,
    this.duration = 0,
    this.durationCompleted = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.additional = false,
    this.timeIntervalEnabled = false,
    this.timeIntervalStart = 420,
    this.timeIntervalEnd = 450,
    this.colorName,
    this.isDeleted,
    Map<String, DateTime>? timestamps,
  }) : timestamps = timestamps ?? {};

  // convert to getter
  Color? resolveColor(ThemeProvider tp) {
    if (colorName != null) {
      final spec = ColorService.habitColorSpecs[colorName!];
      if (spec != null) {
        return tp.isDark ? spec.dark : spec.light;
      }
    }
    if (color == null) return null;
    return hexToColor(color!);
  }

  Color? resolveTextColor(ThemeProvider tp) {
    if (colorName != null) {
      final spec = ColorService.habitColorSpecs[colorName!];
      if (spec != null) {
        return tp.isDark ? spec.darkText : spec.lightText;
      }
    }
    if (color == null) return null;
    return hexToColor(color!);
  }

  Habit copy() {
    return Habit(
      id: id,
      name: name,
      completed: completed,
      streak: streak,
      description: description,
      iconPath: iconPath,
      categoryId: categoryId,
      tag: tag,
      amount: amount,
      amountCompleted: amountCompleted,
      amountLabel: amountLabel,
      duration: duration,
      durationCompleted: durationCompleted,
      longestStreak: longestStreak,
      skipped: skipped,
      additional: additional,
      timeIntervalEnabled: timeIntervalEnabled,
      timeIntervalStart: timeIntervalStart,
      timeIntervalEnd: timeIntervalEnd,
      colorName: colorName,
      isDeleted: isDeleted,
      timestamps: Map<String, DateTime>.from(timestamps),
    );
  }

  Habit copyResetCompletion() {
    return Habit(
      id: id,
      name: name,
      completed: false,
      streak: streak,
      description: description,
      iconPath: iconPath,
      categoryId: categoryId,
      tag: tag,
      amount: amount,
      amountCompleted: 0,
      amountLabel: amountLabel,
      duration: duration,
      durationCompleted: 0,
      longestStreak: longestStreak,
      skipped: false,
      additional: additional,
      timeIntervalEnabled: timeIntervalEnabled,
      timeIntervalStart: timeIntervalStart,
      timeIntervalEnd: timeIntervalEnd,
      colorName: colorName,
      isDeleted: isDeleted,
      timestamps: Map<String, DateTime>.from(timestamps),
    );
  }

  void updateHabit(Habit habit) {
    name = habit.name;
    description = habit.description;
    iconPath = habit.iconPath;
    categoryId = habit.categoryId;
    tag = habit.tag;
    completed = habit.completed;
    skipped = habit.skipped;
    amount = habit.amount;
    amountCompleted = habit.amountCompleted;
    duration = habit.duration;
    durationCompleted = habit.durationCompleted;
    streak = habit.streak;
    longestStreak = habit.longestStreak;
    additional = habit.additional;
    timeIntervalEnabled = habit.timeIntervalEnabled;
    timeIntervalStart = habit.timeIntervalStart;
    timeIntervalEnd = habit.timeIntervalEnd;
    colorName = habit.colorName;
    color = habit.color;
    isDeleted = habit.isDeleted;
    timestamps = Map<String, DateTime>.from(habit.timestamps);
  }

  Future<void> deleteHabit() async {
    isDeleted = true;
  }

  Future<void> completeHabit() async {
    if (skipped) {
      completed = false;
      skipped = false;
      amountCompleted = 0;
      durationCompleted = 0;
      return;
    }

    completed = !completed;
    skipped = false;
    amountCompleted = completed ? amount : 0;
    durationCompleted = completed ? duration : 0;
  }

  Future<void> skipHabit() async {
    skipped = !skipped;
  }

  void updateHabitAmountCompleted(int amountCompleted) {
    if (amountCompleted == amount) {
      completed = true;
    }
    this.amountCompleted = amountCompleted;
  }

  void updateHabitDurationCompleted(int durationCompleted) {
    if (durationCompleted == duration) {
      completed = true;
    }
    this.durationCompleted = durationCompleted;
  }

  Future<void> resetCompletion() async {
    completed = false;
    skipped = false;
    amountCompleted = 0;
    durationCompleted = 0;
  }

  /// Get the habit name color based on theme mode
  Color getNameColor(ThemeProvider tp) {
    return resolveTextColor(tp) ?? tp.primaryTextColor;
  }

  /// Get the habit container color with opacity based on theme mode
  Color getContainerColor(ThemeProvider tp, {bool isCurrentHabit = true}) {
    final opacity = isCurrentHabit ? 0.7 : 0.5;
    final habitColor = resolveColor(tp);
    if (tp.isDark) {
      return habitColor?.withOpacity(opacity) ??
          tp.primaryColor.darken(30).withOpacity(opacity);
    } else {
      return habitColor?.withOpacity(opacity) ??
          tp.primaryColor.lighten(30).withOpacity(opacity);
    }
  }

  /// Check if habit name should be shown based on time type
  bool shouldShowName(TimeType timeType) {
    return !(timeIntervalEnd - timeIntervalStart <= 5 &&
        timeType == TimeType.regular);
  }

  /// Get the time type of the habit (regular, overday, or midnight)
  TimeType getTimeType() {
    return timeIntervalEnd == 0
        ? TimeType.midnight
        : timeIntervalStart > timeIntervalEnd
        ? TimeType.overday
        : TimeType.regular;
  }

  /// Get the duration in hours
  double getTimeDuration() {
    if (getTimeType() == TimeType.regular) {
      return timeIntervalEnd / 60 - timeIntervalStart / 60;
    } else {
      return timeIntervalEnd / 60;
    }
  }

  /// Get the start hour (0-24)
  double getStartHour() {
    return timeIntervalStart / 60;
  }

  /// Get the completion color based on colorfulness preference
  Color getCompletionColor(ThemeProvider tp, Colorfulness colorfulness) {
    if (skipped) {
      return tp.borderColor.darken(tp.isDark ? 0 : 45);
    }

    switch (colorfulness) {
      case Colorfulness.tinted:
        return tp.primaryColor;
      case Colorfulness.standard:
        return tp.successColor;
      case Colorfulness.colorful:
        return resolveColor(tp) ?? tp.successColor;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'categoryId': categoryId,
      'tag': tag,
      'completed': completed,
      'skipped': skipped,
      'amountLabel': amountLabel,
      'amount': amount,
      'amountCompleted': amountCompleted,
      'duration': duration,
      'durationCompleted': durationCompleted,
      'streak': streak,
      'longestStreak': longestStreak,
      'additional': additional,
      'timeIntervalEnabled': timeIntervalEnabled,
      'timeIntervalStart': timeIntervalStart,
      'timeIntervalEnd': timeIntervalEnd,
      'colorName': colorName,
      'color': color,
      'isDeleted': isDeleted,
      'timestamps': timestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> m) {
    final rawTimestamps = m['timestamps'];
    final ts = <String, DateTime>{};
    if (rawTimestamps is Map) {
      rawTimestamps.forEach((key, value) {
        final parsed = DateTime.tryParse(value?.toString() ?? '');
        if (parsed != null) {
          ts[key.toString()] = parsed.toUtc();
        }
      });
    }

    return Habit(
      id: m['id'] as int,
      name: m['name'] as String,
      description: (m['description'] as String?) ?? '',
      iconPath: m['iconPath'] as String,
      categoryId: m['categoryId'] as int,
      amountLabel: (m['amountLabel'] as String?) ?? 'times',
      tag: (m['tag'] as String?) ?? 'No tag',
      completed: (m['completed'] as bool?) ?? false,
      skipped: (m['skipped'] as bool?) ?? false,
      amount: (m['amount'] as int?) ?? 0,
      amountCompleted: (m['amountCompleted'] as int?) ?? 0,
      duration: (m['duration'] as int?) ?? 0,
      durationCompleted: (m['durationCompleted'] as int?) ?? 0,
      streak: (m['streak'] as int?) ?? 0,
      longestStreak: (m['longestStreak'] as int?) ?? 0,
      additional: (m['additional'] as bool?) ?? false,
      timeIntervalEnabled: (m['timeIntervalEnabled'] as bool?) ?? false,
      timeIntervalStart: (m['timeIntervalStart'] as int?) ?? 420,
      timeIntervalEnd: (m['timeIntervalEnd'] as int?) ?? 450,
      colorName: m['colorName'] as String?,
      isDeleted: m['isDeleted'] as bool?,
      timestamps: ts,
    )..color = m['color'] as String?;
  }

  Habit merge(Habit incoming, {DateTime? reference}) {
    final now = (reference ?? DateTime.now()).toUtc();
    final mergedTimestamps = <String, DateTime>{};

    T resolve<T>(String key, T localValue, T incomingValue) {
      if (localValue == incomingValue) {
        return localValue;
      }
      final localTs = timestamps[key];
      final incomingTs = incoming.timestamps[key];

      if (localTs == null && incomingTs == null) {
        return localValue;
      }

      if (localTs != null && incomingTs == null) {
        mergedTimestamps[key] = localTs;
        return localValue;
      }

      if (localTs == null && incomingTs != null) {
        mergedTimestamps[key] = incomingTs;
        return incomingValue;
      }

      final localDelta = now.difference(localTs!).abs();
      final incomingDelta = now.difference(incomingTs!).abs();

      if (localDelta == incomingDelta) {
        mergedTimestamps[key] = localTs;
        return localValue; // Prefer on-device when timestamps tie
      }

      final useLocal = localDelta < incomingDelta;
      mergedTimestamps[key] = useLocal ? localTs : incomingTs;
      return useLocal ? localValue : incomingValue;
    }

    final merged = Habit(
      id: id,
      name: resolve('name', name, incoming.name),
      description: resolve('description', description, incoming.description),
      iconPath: resolve('iconPath', iconPath, incoming.iconPath),
      categoryId: resolve('categoryId', categoryId, incoming.categoryId),
      amountLabel: resolve('amountLabel', amountLabel, incoming.amountLabel),
      tag: resolve('tag', tag, incoming.tag),
      completed: resolve('completed', completed, incoming.completed),
      skipped: resolve('skipped', skipped, incoming.skipped),
      amount: resolve('amount', amount, incoming.amount),
      amountCompleted: resolve(
        'amountCompleted',
        amountCompleted,
        incoming.amountCompleted,
      ),
      duration: resolve('duration', duration, incoming.duration),
      durationCompleted: resolve(
        'durationCompleted',
        durationCompleted,
        incoming.durationCompleted,
      ),
      streak: resolve('streak', streak, incoming.streak),
      longestStreak: resolve(
        'longestStreak',
        longestStreak,
        incoming.longestStreak,
      ),
      additional: resolve('additional', additional, incoming.additional),
      timeIntervalEnabled: resolve(
        'timeIntervalEnabled',
        timeIntervalEnabled,
        incoming.timeIntervalEnabled,
      ),
      timeIntervalStart: resolve(
        'timeIntervalStart',
        timeIntervalStart,
        incoming.timeIntervalStart,
      ),
      timeIntervalEnd: resolve(
        'timeIntervalEnd',
        timeIntervalEnd,
        incoming.timeIntervalEnd,
      ),
      colorName: resolve('colorName', colorName, incoming.colorName),
      isDeleted: resolve('isDeleted', isDeleted, incoming.isDeleted),
      timestamps: mergedTimestamps,
    );

    merged.color = resolve('color', color, incoming.color);

    final allTimestampKeys = {...timestamps.keys, ...incoming.timestamps.keys};

    for (final key in allTimestampKeys) {
      if (mergedTimestamps.containsKey(key)) continue;

      final localTs = timestamps[key];
      final incomingTs = incoming.timestamps[key];

      if (localTs == null && incomingTs == null) {
        continue;
      }

      if (localTs != null && incomingTs == null) {
        mergedTimestamps[key] = localTs;
        continue;
      }

      if (localTs == null && incomingTs != null) {
        mergedTimestamps[key] = incomingTs;
        continue;
      }

      final localDelta = now.difference(localTs!).abs();
      final incomingDelta = now.difference(incomingTs!).abs();

      mergedTimestamps[key] =
          localDelta <= incomingDelta ? localTs : incomingTs;
    }

    return merged;
  }
}
