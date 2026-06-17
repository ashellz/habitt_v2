import 'dart:ui';

import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/old_color_service.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:habitt/util/color_converting.dart';
import 'package:habitt/widgets/habit_details/select_habit_time_page/select_habit_time_body.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:tinycolor2/tinycolor2.dart';

enum HabitTrackingType { amount, duration }

class Habit extends HiveObject {
  final int id;
  String name;
  String description;
  String iconPath;
  int categoryId; // Any time, Morning, Afternoon, Evening
  int order; // order within category
  String tag; // Custom tags, not implemented
  bool completed;
  bool skipped; // deprecated
  String amountLabel; // times, pages, steps
  int amount; // Number of times to do
  int amountCompleted; // Number of times completed
  int duration; // How long to do
  int durationCompleted; // How long has been done
  int streak;
  int longestStreak;
  bool optional;
  bool
  timeIntervalEnabled; // habit has a specific time interval from-to hour range
  int timeIntervalStart; // In minutes
  int timeIntervalEnd; // In minutes
  ScheduleType scheduleType; // daily, weekly, monthly, custom
  int weeklyTarget; // 1,2,3... times a week
  int monthlyTarget; // 1,2,3... times a month
  int customIntervalDays;
  List<int> selectedDaysAWeek; // 1,3,5... 1 = monday
  List<int> selectedDaysAMonth; // 1,3,5... 1 = 1st
  List<String> customAppearance;
  int timesCompletedThisWeek;
  int timesCompletedThisMonth;
  DateTime createdAt; // When habit was created
  DateTime? lastCustomUpdate;
  String? colorName; // Maps to theme-aware palette
  String? color;
  bool notificationsEnabled;
  List<HabitNotificationTime> notificationTimes;
  PremadeHabitType?
  premadeHabitType; // If created from a premade template which type
  HabitTrackingType? trackingType; // amount or duration
  bool? isDeleted;
  bool? isPaused;
  Map<String, DateTime> timestamps;
  DateTime? insightPopstonedUntil;
  Map<String, String> localizedNames;

  Habit({
    required this.id,
    required this.name,
    this.description = "",
    required this.iconPath,
    required this.categoryId,
    this.order = 0,
    this.amountLabel = AmountLabelPreset.defaultAmountLabel,
    this.tag = "No tag",
    this.completed = false,
    this.skipped = false,
    this.amount = 0,
    this.amountCompleted = 0,
    this.duration = 0,
    this.durationCompleted = 0,
    this.streak = 0,
    this.longestStreak = 0,
    this.optional = false,
    this.timeIntervalEnabled = false,
    this.timeIntervalStart = 420,
    this.timeIntervalEnd = 450,
    this.scheduleType = ScheduleType.daily,
    this.weeklyTarget = 1,
    this.monthlyTarget = 1,
    this.customIntervalDays = 2,
    List<int>? selectedDaysAWeek,
    List<int>? selectedDaysAMonth,
    List<String>? customAppearance,
    this.timesCompletedThisWeek = 0,
    this.timesCompletedThisMonth = 0,
    DateTime? createdAt,
    this.lastCustomUpdate,
    this.colorName,
    this.notificationsEnabled = false,
    List<HabitNotificationTime>? notificationTimes,
    this.premadeHabitType,
    this.trackingType,
    this.isDeleted,
    this.isPaused,
    Map<String, DateTime>? timestamps,
    this.insightPopstonedUntil,
    Map<String, String>? localizedNames,
  }) : selectedDaysAWeek = selectedDaysAWeek ?? [],
       selectedDaysAMonth = selectedDaysAMonth ?? [],
       customAppearance = customAppearance ?? [],
       notificationTimes =
           notificationTimes ??
           [
             HabitNotificationTime(
               id: DateTime.now().microsecondsSinceEpoch,
               minutesOfDay: 8 * 60,
             ),
           ],
       createdAt = (createdAt ?? DateTime.now()).toUtc(),
       timestamps = timestamps ?? {},
       localizedNames = localizedNames ?? {} {
    trackingType ??= _inferTrackingType(
      amount: this.amount,
      duration: this.duration,
    );
    this.timestamps['createdAt'] ??= this.createdAt;
  }

  // convert to getter
  Color? resolveColor(ThemeProvider tp) {
    if (colorName != null) {
      final spec = OldColorService.habitColorSpecs[colorName!];
      if (spec != null) {
        return tp.isDark ? spec.dark : spec.light;
      }
    }
    if (color == null) return null;
    return hexToColor(color!);
  }

  Color? resolveTextColor(ThemeProvider tp) {
    if (colorName != null) {
      final spec = OldColorService.habitColorSpecs[colorName!];
      if (spec != null) {
        return tp.isDark ? spec.darkText : spec.lightText;
      }
    }
    if (color == null) return null;
    return hexToColor(color!);
  }

  String resolvedName(String? localeCode) {
    if (localeCode == null) return name;
    final override = localizedNames[localeCode];
    if (override != null && override.isNotEmpty) return override;
    return name;
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
      order: order,
      tag: tag,
      amount: amount,
      amountCompleted: amountCompleted,
      amountLabel: amountLabel,
      duration: duration,
      durationCompleted: durationCompleted,
      longestStreak: longestStreak,
      skipped: skipped,
      optional: optional,
      timeIntervalEnabled: timeIntervalEnabled,
      timeIntervalStart: timeIntervalStart,
      timeIntervalEnd: timeIntervalEnd,
      scheduleType: scheduleType,
      weeklyTarget: weeklyTarget,
      monthlyTarget: monthlyTarget,
      customIntervalDays: customIntervalDays,
      selectedDaysAWeek: List<int>.from(selectedDaysAWeek),
      selectedDaysAMonth: List<int>.from(selectedDaysAMonth),
      customAppearance: List<String>.from(customAppearance),
      timesCompletedThisWeek: timesCompletedThisWeek,
      timesCompletedThisMonth: timesCompletedThisMonth,
      createdAt: createdAt,
      lastCustomUpdate: lastCustomUpdate,
      colorName: colorName,
      notificationsEnabled: notificationsEnabled,
      notificationTimes: notificationTimes.map((slot) => slot.copy()).toList(),
      premadeHabitType: premadeHabitType,
      trackingType: trackingType,
      isDeleted: isDeleted,
      isPaused: isPaused,
      insightPopstonedUntil: insightPopstonedUntil,
      timestamps: Map<String, DateTime>.from(timestamps),
      localizedNames: Map<String, String>.from(localizedNames),
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
      order: order,
      tag: tag,
      amount: amount,
      amountCompleted: 0,
      amountLabel: amountLabel,
      duration: duration,
      durationCompleted: 0,
      longestStreak: longestStreak,
      skipped: false,
      optional: optional,
      timeIntervalEnabled: timeIntervalEnabled,
      timeIntervalStart: timeIntervalStart,
      timeIntervalEnd: timeIntervalEnd,
      scheduleType: scheduleType,
      weeklyTarget: weeklyTarget,
      monthlyTarget: monthlyTarget,
      customIntervalDays: customIntervalDays,
      selectedDaysAWeek: List<int>.from(selectedDaysAWeek),
      selectedDaysAMonth: List<int>.from(selectedDaysAMonth),
      customAppearance: List<String>.from(customAppearance),
      timesCompletedThisWeek: 0,
      timesCompletedThisMonth: 0,
      createdAt: createdAt,
      lastCustomUpdate: lastCustomUpdate,
      colorName: colorName,
      notificationsEnabled: notificationsEnabled,
      notificationTimes: notificationTimes.map((slot) => slot.copy()).toList(),
      premadeHabitType: premadeHabitType,
      trackingType: trackingType,
      isDeleted: isDeleted,
      isPaused: isPaused,
      insightPopstonedUntil: insightPopstonedUntil,
      timestamps: Map<String, DateTime>.from(timestamps),
      localizedNames: Map<String, String>.from(localizedNames),
    );
  }

  void updateHabit(Habit habit) {
    final now = DateTime.now().toUtc();

    if (name != habit.name) {
      name = habit.name;
      timestamps['name'] = now;
    }
    if (description != habit.description) {
      description = habit.description;
      timestamps['description'] = now;
    }
    if (iconPath != habit.iconPath) {
      iconPath = habit.iconPath;
      timestamps['iconPath'] = now;
    }
    if (categoryId != habit.categoryId) {
      categoryId = habit.categoryId;
      timestamps['categoryId'] = now;
    }
    if (order != habit.order) {
      order = habit.order;
      timestamps['order'] = now;
    }
    if (tag != habit.tag) {
      tag = habit.tag;
      timestamps['tag'] = now;
    }
    if (completed != habit.completed) {
      completed = habit.completed;
      timestamps['completed'] = now;
    }
    if (skipped != habit.skipped) {
      skipped = habit.skipped;
      timestamps['skipped'] = now;
    }
    if (amount != habit.amount) {
      amount = habit.amount;
      timestamps['amount'] = now;
    }
    if (amountCompleted != habit.amountCompleted) {
      amountCompleted = habit.amountCompleted;
      timestamps['amountCompleted'] = now;
    }
    if (duration != habit.duration) {
      duration = habit.duration;
      timestamps['duration'] = now;
    }
    if (durationCompleted != habit.durationCompleted) {
      durationCompleted = habit.durationCompleted;
      timestamps['durationCompleted'] = now;
    }
    if (streak != habit.streak) {
      streak = habit.streak;
      timestamps['streak'] = now;
    }
    if (longestStreak != habit.longestStreak) {
      longestStreak = habit.longestStreak;
      timestamps['longestStreak'] = now;
    }
    if (optional != habit.optional) {
      optional = habit.optional;
      timestamps['optional'] = now;
    }
    if (timeIntervalEnabled != habit.timeIntervalEnabled) {
      timeIntervalEnabled = habit.timeIntervalEnabled;
      timestamps['timeIntervalEnabled'] = now;
    }
    if (timeIntervalStart != habit.timeIntervalStart) {
      timeIntervalStart = habit.timeIntervalStart;
      timestamps['timeIntervalStart'] = now;
    }
    if (timeIntervalEnd != habit.timeIntervalEnd) {
      timeIntervalEnd = habit.timeIntervalEnd;
      timestamps['timeIntervalEnd'] = now;
    }
    if (scheduleType != habit.scheduleType) {
      scheduleType = habit.scheduleType;
      timestamps['scheduleType'] = now;
    }
    if (weeklyTarget != habit.weeklyTarget) {
      weeklyTarget = habit.weeklyTarget;
      timestamps['weeklyTarget'] = now;
    }
    if (monthlyTarget != habit.monthlyTarget) {
      monthlyTarget = habit.monthlyTarget;
      timestamps['monthlyTarget'] = now;
    }
    if (customIntervalDays != habit.customIntervalDays) {
      customIntervalDays = habit.customIntervalDays;
      timestamps['customIntervalDays'] = now;
    }
    if (!_sameIntList(selectedDaysAWeek, habit.selectedDaysAWeek)) {
      selectedDaysAWeek = List<int>.from(habit.selectedDaysAWeek);
      timestamps['selectedDaysAWeek'] = now;
    }
    if (!_sameIntList(selectedDaysAMonth, habit.selectedDaysAMonth)) {
      selectedDaysAMonth = List<int>.from(habit.selectedDaysAMonth);
      timestamps['selectedDaysAMonth'] = now;
    }
    if (!_sameStringList(customAppearance, habit.customAppearance)) {
      customAppearance = List<String>.from(habit.customAppearance);
      timestamps['customAppearance'] = now;
    }
    if (timesCompletedThisWeek != habit.timesCompletedThisWeek) {
      timesCompletedThisWeek = habit.timesCompletedThisWeek;
      timestamps['timesCompletedThisWeek'] = now;
    }
    if (timesCompletedThisMonth != habit.timesCompletedThisMonth) {
      timesCompletedThisMonth = habit.timesCompletedThisMonth;
      timestamps['timesCompletedThisMonth'] = now;
    }
    if (createdAt != habit.createdAt) {
      createdAt = habit.createdAt;
      timestamps['createdAt'] = now;
    }
    if (lastCustomUpdate != habit.lastCustomUpdate) {
      lastCustomUpdate = habit.lastCustomUpdate;
      timestamps['lastCustomUpdate'] = now;
    }
    if (colorName != habit.colorName) {
      colorName = habit.colorName;
      timestamps['colorName'] = now;
    }
    if (color != habit.color) {
      color = habit.color;
      timestamps['color'] = now;
    }
    if (notificationsEnabled != habit.notificationsEnabled) {
      notificationsEnabled = habit.notificationsEnabled;
      timestamps['notificationsEnabled'] = now;
    }
    if (!_sameNotificationList(notificationTimes, habit.notificationTimes)) {
      notificationTimes =
          habit.notificationTimes.map((slot) => slot.copy()).toList();
      timestamps['notificationTimes'] = now;
    }
    if (premadeHabitType != habit.premadeHabitType) {
      premadeHabitType = habit.premadeHabitType;
      timestamps['premadeHabitType'] = now;
    }
    if (trackingType != habit.trackingType) {
      trackingType = habit.trackingType;
      timestamps['trackingType'] = now;
    }
    if (isDeleted != habit.isDeleted) {
      isDeleted = habit.isDeleted;
      timestamps['isDeleted'] = now;
    }
    if (insightPopstonedUntil != habit.insightPopstonedUntil) {
      insightPopstonedUntil = habit.insightPopstonedUntil;
      timestamps['insightPopstonedUntil'] = now;
    }
    if (isPaused != habit.isPaused) {
      isPaused = habit.isPaused;
      timestamps['isPaused'] = now;
    }
    if (!_sameStringMap(localizedNames, habit.localizedNames)) {
      localizedNames = Map<String, String>.from(habit.localizedNames);
      timestamps['localizedNames'] = now;
    }
  }

  /// Apply the result of a [merge] call directly, preserving the
  /// merge-resolved timestamps instead of stamping everything with
  /// [DateTime.now] like [updateHabit] does.  Use this in sync/merge
  /// code paths; use [updateHabit] only for real user edits.
  void applyMerge(Habit merged) {
    name = merged.name;
    description = merged.description;
    iconPath = merged.iconPath;
    categoryId = merged.categoryId;
    order = merged.order;
    tag = merged.tag;
    completed = merged.completed;
    skipped = merged.skipped;
    amount = merged.amount;
    amountCompleted = merged.amountCompleted;
    amountLabel = merged.amountLabel;
    duration = merged.duration;
    durationCompleted = merged.durationCompleted;
    streak = merged.streak;
    longestStreak = merged.longestStreak;
    optional = merged.optional;
    timeIntervalEnabled = merged.timeIntervalEnabled;
    timeIntervalStart = merged.timeIntervalStart;
    timeIntervalEnd = merged.timeIntervalEnd;
    scheduleType = merged.scheduleType;
    weeklyTarget = merged.weeklyTarget;
    monthlyTarget = merged.monthlyTarget;
    customIntervalDays = merged.customIntervalDays;
    selectedDaysAWeek = List<int>.from(merged.selectedDaysAWeek);
    selectedDaysAMonth = List<int>.from(merged.selectedDaysAMonth);
    customAppearance = List<String>.from(merged.customAppearance);
    timesCompletedThisWeek = merged.timesCompletedThisWeek;
    timesCompletedThisMonth = merged.timesCompletedThisMonth;
    createdAt = merged.createdAt;
    lastCustomUpdate = merged.lastCustomUpdate;
    colorName = merged.colorName;
    color = merged.color;
    notificationsEnabled = merged.notificationsEnabled;
    notificationTimes =
        merged.notificationTimes.map((s) => s.copy()).toList();
    premadeHabitType = merged.premadeHabitType;
    trackingType = merged.trackingType;
    isDeleted = merged.isDeleted;
    isPaused = merged.isPaused;
    insightPopstonedUntil = merged.insightPopstonedUntil;
    localizedNames = Map<String, String>.from(merged.localizedNames);
    timestamps
      ..clear()
      ..addAll(merged.timestamps);
  }

  Future<void> deleteHabit() async {
    isDeleted = true;
    timestamps['isDeleted'] = DateTime.now().toUtc();
  }

  Future<void> pauseHabit() async {
    isPaused = true;
    timestamps['isPaused'] = DateTime.now().toUtc();
  }

  Future<void> unpauseHabit() async {
    isPaused = false;
    timestamps['isPaused'] = DateTime.now().toUtc();
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
    timestamps['completed'] = DateTime.now().toUtc();
    timestamps['skipped'] = DateTime.now().toUtc();
    timestamps['amountCompleted'] = DateTime.now().toUtc();
    timestamps['durationCompleted'] = DateTime.now().toUtc();
  }

  Future<void> skipHabit() async {
    skipped = !skipped;
    timestamps['skipped'] = DateTime.now().toUtc();
  }

  void updateHabitAmountCompleted(int amountCompleted) {
    final bool wasCompleted = completed;
    if (amountCompleted >= amount) {
      completed = true;
    } else if (completed) {
      completed = false;
    }
    if (completed != wasCompleted) {
      timestamps['completed'] = DateTime.now().toUtc();
    }
    this.amountCompleted = amountCompleted;
    timestamps['amountCompleted'] = DateTime.now().toUtc();
  }

  void updateHabitDurationCompleted(int durationCompleted) {
    final bool wasCompleted = completed;
    if (durationCompleted >= duration) {
      completed = true;
    } else if (completed) {
      completed = false;
    }
    if (completed != wasCompleted) {
      timestamps['completed'] = DateTime.now().toUtc();
    }
    this.durationCompleted = durationCompleted;
    timestamps['durationCompleted'] = DateTime.now().toUtc();
  }

  Future<void> resetCompletion() async {
    completed = false;
    skipped = false;
    amountCompleted = 0;
    durationCompleted = 0;
    // Do NOT update timestamps — this is a local day-boundary reset, not a
    // user action. Updating timestamps here would cause the reset to win over
    // genuine completions from another device when the merge runs later.
  }

  Future<void> resetScheduleCounters({
    required bool resetWeekly,
    required bool resetMonthly,
  }) async {
    final now = DateTime.now().toUtc();

    if (resetWeekly) {
      timesCompletedThisWeek = 0;
      timestamps['timesCompletedThisWeek'] = now;
    }

    if (resetMonthly) {
      timesCompletedThisMonth = 0;
      timestamps['timesCompletedThisMonth'] = now;
    }
  }

  void updateScheduleCountersOnCompletionToggle({
    required bool wasCompleted,
    required bool isCompleted,
    int? weeklyBaseCount,
    int? monthlyBaseCount,
  }) {
    final now = DateTime.now().toUtc();

    if (scheduleType == ScheduleType.weekly && selectedDaysAWeek.isEmpty) {
      final base = weeklyBaseCount ?? timesCompletedThisWeek;
      if (!wasCompleted && isCompleted) {
        timesCompletedThisWeek = (base + 1).clamp(0, weeklyTarget);
        timestamps['timesCompletedThisWeek'] = now;
      } else if (wasCompleted && !isCompleted) {
        timesCompletedThisWeek = (base - 1).clamp(0, weeklyTarget);
        timestamps['timesCompletedThisWeek'] = now;
      }
    }

    if (scheduleType == ScheduleType.monthly && selectedDaysAMonth.isEmpty) {
      final base = monthlyBaseCount ?? timesCompletedThisMonth;
      if (!wasCompleted && isCompleted) {
        timesCompletedThisMonth = (base + 1).clamp(0, monthlyTarget);
        timestamps['timesCompletedThisMonth'] = now;
      } else if (wasCompleted && !isCompleted) {
        timesCompletedThisMonth = (base - 1).clamp(0, monthlyTarget);
        timestamps['timesCompletedThisMonth'] = now;
      }
    }
  }

  void updateStreak({required int streak, required int longestStreak}) {
    final now = DateTime.now().toUtc();
    this.streak = streak;
    timestamps['streak'] = now;

    final nextLongest =
        longestStreak > this.longestStreak ? longestStreak : this.longestStreak;
    if (nextLongest != this.longestStreak) {
      this.longestStreak = nextLongest;
      timestamps['longestStreak'] = now;
    }
  }

  void setLongestStreak(int value) {
    if (value == longestStreak) return;
    longestStreak = value;
    timestamps['longestStreak'] = DateTime.now().toUtc();
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

  bool get tracksAmount => trackingType == HabitTrackingType.amount;

  bool get tracksDuration => trackingType == HabitTrackingType.duration;

  bool get hasTrackingType => trackingType != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'categoryId': categoryId,
      'order': order,
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
      'optional': optional,
      'timeIntervalEnabled': timeIntervalEnabled,
      'timeIntervalStart': timeIntervalStart,
      'timeIntervalEnd': timeIntervalEnd,
      'scheduleType': _serializeScheduleType(scheduleType),
      'weeklyTarget': weeklyTarget,
      'monthlyTarget': monthlyTarget,
      'customIntervalDays': customIntervalDays,
      'selectedDaysAWeek': selectedDaysAWeek,
      'selectedDaysAMonth': selectedDaysAMonth,
      'customAppearance': customAppearance,
      'timesCompletedThisWeek': timesCompletedThisWeek,
      'timesCompletedThisMonth': timesCompletedThisMonth,
      'createdAt': createdAt.toIso8601String(),
      'lastCustomUpdate': lastCustomUpdate?.toIso8601String(),
      'colorName': colorName,
      'color': color,
      'notificationsEnabled': notificationsEnabled,
      'notificationTimes':
          notificationTimes
              .map((notification) => notification.toMap())
              .toList(),
      'premadeHabitType': _serializePremadeHabitType(premadeHabitType),
      'trackingType': _serializeTrackingType(trackingType),
      'isDeleted': isDeleted,
      'isPaused': isPaused,
      'insightPopstonedUntil': insightPopstonedUntil?.toIso8601String(),
      'timestamps': timestamps.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'localizedNames': localizedNames,
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
      order: (m['order'] as num?)?.toInt() ?? 0,
      amountLabel:
          (m['amountLabel'] as String?) ?? AmountLabelPreset.times.plural,
      tag: (m['tag'] as String?) ?? 'No tag',
      completed: (m['completed'] as bool?) ?? false,
      skipped: (m['skipped'] as bool?) ?? false,
      amount: (m['amount'] as int?) ?? 0,
      amountCompleted: (m['amountCompleted'] as int?) ?? 0,
      duration: (m['duration'] as int?) ?? 0,
      durationCompleted: (m['durationCompleted'] as int?) ?? 0,
      streak: (m['streak'] as int?) ?? 0,
      longestStreak: (m['longestStreak'] as int?) ?? 0,
      optional: (m['optional'] as bool?) ?? false,
      timeIntervalEnabled: (m['timeIntervalEnabled'] as bool?) ?? false,
      timeIntervalStart: (m['timeIntervalStart'] as int?) ?? 420,
      timeIntervalEnd: (m['timeIntervalEnd'] as int?) ?? 450,
      scheduleType: _deserializeScheduleType(
        m['scheduleType']?.toString() ?? 'daily',
      ),
      weeklyTarget: (m['weeklyTarget'] as int?) ?? 1,
      monthlyTarget: (m['monthlyTarget'] as int?) ?? 1,
      customIntervalDays: (m['customIntervalDays'] as int?) ?? 2,
      selectedDaysAWeek: _parseIntList(m['selectedDaysAWeek']),
      selectedDaysAMonth: _parseIntList(m['selectedDaysAMonth']),
      customAppearance: _parseStringList(m['customAppearance']),
      timesCompletedThisWeek: (m['timesCompletedThisWeek'] as int?) ?? 0,
      timesCompletedThisMonth: (m['timesCompletedThisMonth'] as int?) ?? 0,
      createdAt:
          DateTime.tryParse(m['createdAt']?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      lastCustomUpdate:
          DateTime.tryParse(m['lastCustomUpdate']?.toString() ?? '')?.toUtc(),
      colorName: m['colorName'] as String?,
      notificationsEnabled: (m['notificationsEnabled'] as bool?) ?? false,
      notificationTimes: _parseNotificationTimes(m['notificationTimes']),
      premadeHabitType: _deserializePremadeHabitType(
        m['premadeHabitType']?.toString(),
      ),
      trackingType:
          _deserializeTrackingType(m['trackingType']?.toString()) ??
          _inferTrackingType(
            amount: (m['amount'] as int?) ?? 0,
            duration: (m['duration'] as int?) ?? 0,
          ),
      isDeleted: m['isDeleted'] as bool?,
      isPaused: m['isPaused'] as bool?,
      insightPopstonedUntil:
          DateTime.tryParse(
            m['insightPopstonedUntil']?.toString() ?? '',
          )?.toUtc(),
      timestamps: ts,
      localizedNames: _parseStringMap(m['localizedNames']),
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
      order: resolve('order', order, incoming.order),
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
      optional: resolve('optional', optional, incoming.optional),
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
      scheduleType: resolve(
        'scheduleType',
        scheduleType,
        incoming.scheduleType,
      ),
      weeklyTarget: resolve(
        'weeklyTarget',
        weeklyTarget,
        incoming.weeklyTarget,
      ),
      monthlyTarget: resolve(
        'monthlyTarget',
        monthlyTarget,
        incoming.monthlyTarget,
      ),
      customIntervalDays: resolve(
        'customIntervalDays',
        customIntervalDays,
        incoming.customIntervalDays,
      ),
      selectedDaysAWeek: resolve(
        'selectedDaysAWeek',
        List<int>.from(selectedDaysAWeek),
        List<int>.from(incoming.selectedDaysAWeek),
      ),
      selectedDaysAMonth: resolve(
        'selectedDaysAMonth',
        List<int>.from(selectedDaysAMonth),
        List<int>.from(incoming.selectedDaysAMonth),
      ),
      customAppearance: resolve(
        'customAppearance',
        List<String>.from(customAppearance),
        List<String>.from(incoming.customAppearance),
      ),
      timesCompletedThisWeek: resolve(
        'timesCompletedThisWeek',
        timesCompletedThisWeek,
        incoming.timesCompletedThisWeek,
      ),
      timesCompletedThisMonth: resolve(
        'timesCompletedThisMonth',
        timesCompletedThisMonth,
        incoming.timesCompletedThisMonth,
      ),
      createdAt: resolve('createdAt', createdAt, incoming.createdAt),
      lastCustomUpdate: resolve(
        'lastCustomUpdate',
        lastCustomUpdate,
        incoming.lastCustomUpdate,
      ),
      colorName: resolve('colorName', colorName, incoming.colorName),
      notificationsEnabled: resolve(
        'notificationsEnabled',
        notificationsEnabled,
        incoming.notificationsEnabled,
      ),
      notificationTimes: resolve(
        'notificationTimes',
        notificationTimes.map((slot) => slot.copy()).toList(),
        incoming.notificationTimes.map((slot) => slot.copy()).toList(),
      ),
      premadeHabitType: resolve(
        'premadeHabitType',
        premadeHabitType,
        incoming.premadeHabitType,
      ),
      insightPopstonedUntil: resolve(
        'insightPopstonedUntil',
        insightPopstonedUntil,
        incoming.insightPopstonedUntil,
      ),
      trackingType: resolve(
        'trackingType',
        trackingType,
        incoming.trackingType,
      ),
      isDeleted: resolve('isDeleted', isDeleted, incoming.isDeleted),
      isPaused: resolve('isPaused', isPaused, incoming.isPaused),
      timestamps: mergedTimestamps,
      localizedNames: resolve(
        'localizedNames',
        Map<String, String>.from(localizedNames),
        Map<String, String>.from(incoming.localizedNames),
      ),
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

  static bool _sameIntList(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sameStringMap(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  static bool _sameNotificationList(
    List<HabitNotificationTime> a,
    List<HabitNotificationTime> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].minutesOfDay != b[i].minutesOfDay ||
          !_sameIntList(a[i].days, b[i].days)) {
        return false;
      }
    }
    return true;
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is! List) return [];
    return value
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).toList();
  }

  static Map<String, String> _parseStringMap(dynamic value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        entry.key.toString(): entry.value.toString(),
    };
  }

  static List<HabitNotificationTime> _parseNotificationTimes(dynamic value) {
    if (value is! List) {
      return [
        HabitNotificationTime(
          id: DateTime.now().microsecondsSinceEpoch,
          minutesOfDay: 8 * 60,
        ),
      ];
    }

    final parsed =
        value
            .whereType<Map>()
            .map(
              (entry) => HabitNotificationTime.fromMap(
                Map<String, dynamic>.from(entry),
              ),
            )
            .toList();

    if (parsed.isEmpty) {
      return [
        HabitNotificationTime(
          id: DateTime.now().microsecondsSinceEpoch,
          minutesOfDay: 8 * 60,
        ),
      ];
    }

    return parsed;
  }

  /// Serialize ScheduleType to String for Hive storage
  static String _serializeScheduleType(ScheduleType scheduleType) {
    return scheduleType.name;
  }

  /// Deserialize String to ScheduleType from Hive storage
  static ScheduleType _deserializeScheduleType(String value) {
    return ScheduleType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ScheduleType.daily,
    );
  }

  static String? _serializePremadeHabitType(PremadeHabitType? type) {
    return type?.name;
  }

  static PremadeHabitType? _deserializePremadeHabitType(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final type in PremadeHabitType.values) {
      if (type.name == value) {
        return type;
      }
    }

    return null;
  }

  static String? _serializeTrackingType(HabitTrackingType? type) {
    return type?.name;
  }

  static HabitTrackingType? _deserializeTrackingType(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final type in HabitTrackingType.values) {
      if (type.name == value) {
        return type;
      }
    }

    return null;
  }

  static HabitTrackingType? _inferTrackingType({
    required int amount,
    required int duration,
  }) {
    if (amount >= 1) {
      return HabitTrackingType.amount;
    }

    if (duration > 0) {
      return HabitTrackingType.duration;
    }

    return null;
  }
}
