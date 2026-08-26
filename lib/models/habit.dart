import 'dart:ui';

import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/models/health_metric_type.dart';
import 'package:habitt/models/health_session_detail.dart';
import 'package:habitt/models/health_workout_type.dart';
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

enum HabitTrackingType {
  amount,
  duration,
  // A single point in time, minutes-since-midnight, stored in amount/
  // amountCompleted like an amount goal — but "earlier is better":
  // completed = amountCompleted <= amount + toleranceMinutes.
  // amount = target (bedtime goal - 10pm = 1320),
  // amountCompleted = actual (bedtime logged - 10:15pm = 1335)
  timeOfDay,
}

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
  String? soundKey; // null = inherit the global notification sound
  PremadeHabitType?
  premadeHabitType; // If created from a premade template which type
  HabitTrackingType? trackingType; // amount or duration
  HealthMetricType?
  healthMetric; // if set, progress is synced from this Health metric
  HealthWorkoutType?
  healthWorkoutFilter; // narrows healthMetric == workouts to one workout type; null = any (all)
  int toleranceMinutes; // forgiveness for amount/timeOfDay goals — 15m/30m/60m presets; 0 = none
  List<HealthSessionDetail>
  healthSessions; // individual workout or sleep sessions Health returned in a day
  bool? isDeleted;
  bool? isPaused;
  DateTime? deletedAt;
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
    this.soundKey,
    this.premadeHabitType,
    this.trackingType,
    this.healthMetric,
    this.healthWorkoutFilter,
    this.toleranceMinutes = 0, // no forgiveness unless explicitly set
    List<HealthSessionDetail>? healthSessions,
    this.isDeleted,
    this.isPaused,
    this.deletedAt,
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
       healthSessions = healthSessions ?? [],
       createdAt = (createdAt ?? DateTime.now()).toUtc(),
       timestamps = timestamps ?? {},
       localizedNames = localizedNames ?? {} {
    trackingType ??= _inferTrackingType(
      amount: amount,
      duration: duration,
      healthMetric: healthMetric,
    );
    this.timestamps['createdAt'] ??= this.createdAt;
  }

  bool hasAnyProgress() {
    return completed || amountCompleted > 0 || durationCompleted > 0;
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
      soundKey: soundKey,
      premadeHabitType: premadeHabitType,
      trackingType: trackingType,
      healthMetric: healthMetric,
      healthWorkoutFilter: healthWorkoutFilter,
      toleranceMinutes: toleranceMinutes,
      healthSessions: healthSessions.map((s) => s.copy()).toList(),
      isDeleted: isDeleted,
      isPaused: isPaused,
      deletedAt: deletedAt,
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
      soundKey: soundKey,
      premadeHabitType: premadeHabitType,
      trackingType: trackingType,
      healthMetric: healthMetric,
      healthWorkoutFilter: healthWorkoutFilter,
      toleranceMinutes: toleranceMinutes,
      healthSessions: const [],
      isDeleted: isDeleted,
      isPaused: isPaused,
      deletedAt: deletedAt,
      insightPopstonedUntil: insightPopstonedUntil,
      timestamps: Map<String, DateTime>.from(timestamps),
      localizedNames: Map<String, String>.from(localizedNames),
    );
  }

  void updateHabit(Habit habit) {
    final now = DateTime.now().toUtc();

    final trackingTypeChanged = trackingType != habit.trackingType;
    final amountGoalChanged = amount != habit.amount;
    final durationGoalChanged = duration != habit.duration;
    final toleranceChanged = toleranceMinutes != habit.toleranceMinutes;
    final newTrackingType = habit.trackingType;

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
    if (soundKey != habit.soundKey) {
      soundKey = habit.soundKey;
      timestamps['soundKey'] = now;
    }
    if (premadeHabitType != habit.premadeHabitType) {
      premadeHabitType = habit.premadeHabitType;
      timestamps['premadeHabitType'] = now;
    }
    if (trackingType != habit.trackingType) {
      trackingType = habit.trackingType;
      timestamps['trackingType'] = now;
    }
    if (healthMetric != habit.healthMetric) {
      healthMetric = habit.healthMetric;
      timestamps['healthMetric'] = now;
    }
    if (healthWorkoutFilter != habit.healthWorkoutFilter) {
      healthWorkoutFilter = habit.healthWorkoutFilter;
      timestamps['healthWorkoutFilter'] = now;
    }
    if (toleranceMinutes != habit.toleranceMinutes) {
      toleranceMinutes = habit.toleranceMinutes;
      timestamps['toleranceMinutes'] = now;
    }
    if (isDeleted != habit.isDeleted) {
      isDeleted = habit.isDeleted;
      deletedAt = habit.isDeleted == true ? now : null;
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

    if (trackingTypeChanged) {
      if (completed || amountCompleted != 0 || durationCompleted != 0) {
        completed = false;
        amountCompleted = 0;
        durationCompleted = 0;
        timestamps['completed'] = now;
        timestamps['amountCompleted'] = now;
        timestamps['durationCompleted'] = now;
      }
    } else if (newTrackingType == HabitTrackingType.duration &&
        durationGoalChanged) {
      final shouldBeCompleted = durationCompleted >= duration;
      if (completed != shouldBeCompleted) {
        completed = shouldBeCompleted;
        timestamps['completed'] = now;
      }
    } else if (newTrackingType == HabitTrackingType.amount &&
        amountGoalChanged) {
      final shouldBeCompleted = amountCompleted >= amount;
      if (completed != shouldBeCompleted) {
        completed = shouldBeCompleted;
        timestamps['completed'] = now;
      }
    } else if (newTrackingType == HabitTrackingType.timeOfDay &&
        (amountGoalChanged || toleranceChanged)) {
      final shouldBeCompleted = amountCompleted <= amount + toleranceMinutes;
      if (completed != shouldBeCompleted) {
        completed = shouldBeCompleted;
        timestamps['completed'] = now;
      }
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
    notificationTimes = merged.notificationTimes.map((s) => s.copy()).toList();
    soundKey = merged.soundKey;
    premadeHabitType = merged.premadeHabitType;
    trackingType = merged.trackingType;
    healthMetric = merged.healthMetric;
    healthWorkoutFilter = merged.healthWorkoutFilter;
    toleranceMinutes = merged.toleranceMinutes;
    healthSessions = merged.healthSessions.map((s) => s.copy()).toList();
    isDeleted = merged.isDeleted;
    isPaused = merged.isPaused;
    deletedAt = merged.deletedAt;
    insightPopstonedUntil = merged.insightPopstonedUntil;
    localizedNames = Map<String, String>.from(merged.localizedNames);
    timestamps
      ..clear()
      ..addAll(merged.timestamps);
  }

  Future<void> deleteHabit() async {
    isDeleted = true;
    deletedAt = DateTime.now().toUtc();
    timestamps['isDeleted'] = deletedAt!;
  }

  Future<void> pauseHabit() async {
    isPaused = true;
    timestamps['isPaused'] = DateTime.now().toUtc();
  }

  Future<void> unpauseHabit() async {
    isPaused = false;
    timestamps['isPaused'] = DateTime.now().toUtc();
  }

  Future<void> restore() async {
    isDeleted = false;
    deletedAt = null;
    timestamps['isDeleted'] = DateTime.now().toUtc();
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

  /// completed = amountCompleted >= amount - toleranceMinutes. toleranceMinutes
  /// defaults to 0 for every habit that doesn't explicitly set one (see the
  /// Habit constructor), so this reduces to the plain `>=` comparison for
  /// ordinary amount habits — the tolerance is currently only ever set by
  /// the `sleep` Health metric.
  void updateHabitAmountCompleted(int amountCompleted) {
    final bool wasCompleted = completed;
    if (amountCompleted >= amount - toleranceMinutes) {
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

  /// For [HabitTrackingType.timeOfDay] habits (bedtime/wake-time)
  /// Unlike amount/duration, earlier is better: completed if [minutesOfDay] is at
  /// or before the target plus [toleranceMinutes]
  void updateHabitTimeOfDayCompleted(int minutesOfDay) {
    final bool wasCompleted = completed;
    // minutesOfDay is minutes since midnight based on real health data
    // eg. 4am is 4*60 = 240

    // if minutesOfDay (22pm) is smaller or equal to amount (22pm) + tolerance (30m) = 22:30pm, then completed = true
    // if for example minutesOfDay is 23:00pm (1380) and amount is 22:00pm (1320) and tolerance is 30m, then completed = false
    if (minutesOfDay <= amount + toleranceMinutes) {
      completed = true;
    } else if (completed) {
      completed = false;
    }
    if (completed != wasCompleted) {
      timestamps['completed'] = DateTime.now().toUtc();
    }
    amountCompleted = minutesOfDay;
    timestamps['amountCompleted'] = DateTime.now().toUtc();
  }

  Future<void> resetCompletion() async {
    completed = false;
    skipped = false;
    amountCompleted = 0;
    durationCompleted = 0;
    healthSessions = [];
    // not updating timestamp because this is an auto reset, not user action
    // updating timestamps would cause bad syncing
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
      'soundKey': soundKey,
      'notificationTimes':
          notificationTimes
              .map((notification) => notification.toMap())
              .toList(),
      'premadeHabitType': _serializePremadeHabitType(premadeHabitType),
      'trackingType': _serializeTrackingType(trackingType),
      'healthMetric': _serializeHealthMetricType(healthMetric),
      'healthWorkoutFilter': healthWorkoutFilter?.name,
      'toleranceMinutes': toleranceMinutes,
      'healthSessions': healthSessions.map((s) => s.toMap()).toList(),
      'isDeleted': isDeleted,
      'isPaused': isPaused,
      'deletedAt': deletedAt?.toIso8601String(),
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

    final parsedHealthMetric = _deserializeHealthMetricType(
      m['healthMetric']?.toString(),
    );

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
      soundKey: m['soundKey'] as String?,
      notificationTimes: _parseNotificationTimes(m['notificationTimes']),
      premadeHabitType: _deserializePremadeHabitType(
        m['premadeHabitType']?.toString(),
      ),
      trackingType:
          _deserializeTrackingType(m['trackingType']?.toString()) ??
          _inferTrackingType(
            amount: (m['amount'] as int?) ?? 0,
            duration: (m['duration'] as int?) ?? 0,
            healthMetric: parsedHealthMetric,
          ),
      healthMetric: parsedHealthMetric,
      healthWorkoutFilter: _deserializeHealthWorkoutType(
        m['healthWorkoutFilter']?.toString(),
      ),
      toleranceMinutes: (m['toleranceMinutes'] as num?)?.toInt() ?? 0,
      healthSessions: _parseHealthSessions(m['healthSessions']),
      isDeleted: m['isDeleted'] as bool?,
      isPaused: m['isPaused'] as bool?,
      deletedAt: DateTime.tryParse(m['deletedAt']?.toString() ?? '')?.toUtc(),
      insightPopstonedUntil:
          DateTime.tryParse(
            m['insightPopstonedUntil']?.toString() ?? '',
          )?.toUtc(),
      timestamps: ts,
      localizedNames: _parseStringMap(m['localizedNames']),
    )..color = m['color'] as String?;
  }

  // These are now merged together, they decide on final completion value
  static const List<String> dayStateKeys = [
    'completed',
    'skipped',
    'amountCompleted',
    'durationCompleted',
  ];

  // Function to apply the same habit stats but from daysBox
  void adoptDayState(Habit source) {
    completed = source.completed;
    skipped = source.skipped;
    amountCompleted = source.amountCompleted;
    durationCompleted = source.durationCompleted;
    healthSessions = source.healthSessions.map((s) => s.copy()).toList();

    for (final key in dayStateKeys) {
      final ts = source.timestamps[key];
      if (ts != null) {
        timestamps[key] = ts;
      } else {
        timestamps.remove(key);
      }
    }
  }

  // clears a habit completely
  // used on backup restoring for habits that have no entry in today snapshot
  // their stored day-state belongs to the day the backup was made.
  void clearDayState() {
    completed = false;
    skipped = false;
    amountCompleted = 0;
    durationCompleted = 0;
    healthSessions = [];
    for (final key in dayStateKeys) {
      timestamps.remove(key);
    }
  }

  /// Latest timestamp among [keys] in [ts], or null if none present.
  static DateTime? _latestTs(Map<String, DateTime> ts, List<String> keys) {
    DateTime? latest;
    for (final key in keys) {
      final value = ts[key];
      if (value == null) continue;
      if (latest == null || value.isAfter(latest)) {
        latest = value;
      }
    }
    return latest;
  }

  // preserveLocalDayState == true -> local values win
  // false -> values with the most recent timestamp win (tie -> local wins)
  Habit merge(
    Habit incoming, {
    DateTime? reference,
    bool preserveLocalDayState = false,
  }) {
    final now = (reference ?? DateTime.now()).toUtc();
    final mergedTimestamps = <String, DateTime>{};

    // Resolve the completion tuple as a single unit.
    final bool useLocalDayState;
    if (preserveLocalDayState) {
      useLocalDayState = true;
    } else {
      final localTupleTs = _latestTs(timestamps, dayStateKeys);
      final incomingTupleTs = _latestTs(incoming.timestamps, dayStateKeys);
      if (localTupleTs == null && incomingTupleTs == null) {
        useLocalDayState = true; // values equal/default — prefer on-device
      } else if (incomingTupleTs == null) {
        useLocalDayState = true;
      } else if (localTupleTs == null) {
        useLocalDayState = false;
      } else {
        final localDelta = now.difference(localTupleTs).abs();
        final incomingDelta = now.difference(incomingTupleTs).abs();
        useLocalDayState = localDelta <= incomingDelta; // tie → local
      }
    }

    T pickDayState<T>(String key, T localValue, T incomingValue) {
      final ts = useLocalDayState ? timestamps[key] : incoming.timestamps[key];
      if (ts != null) {
        mergedTimestamps[key] = ts;
      }
      return useLocalDayState ? localValue : incomingValue;
    }

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
      completed: pickDayState('completed', completed, incoming.completed),
      skipped: pickDayState('skipped', skipped, incoming.skipped),
      amount: resolve('amount', amount, incoming.amount),
      amountCompleted: pickDayState(
        'amountCompleted',
        amountCompleted,
        incoming.amountCompleted,
      ),
      duration: resolve('duration', duration, incoming.duration),
      durationCompleted: pickDayState(
        'durationCompleted',
        durationCompleted,
        incoming.durationCompleted,
      ),
      // No dedicated timestamp key, uses the same tuple decision as
      // amountCompleted/durationCompleted
      healthSessions: pickDayState(
        'healthSessions',
        healthSessions.map((s) => s.copy()).toList(),
        incoming.healthSessions.map((s) => s.copy()).toList(),
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
      soundKey: resolve('soundKey', soundKey, incoming.soundKey),
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
      healthMetric: resolve(
        'healthMetric',
        healthMetric,
        incoming.healthMetric,
      ),
      healthWorkoutFilter: resolve(
        'healthWorkoutFilter',
        healthWorkoutFilter,
        incoming.healthWorkoutFilter,
      ),
      toleranceMinutes: resolve(
        'toleranceMinutes',
        toleranceMinutes,
        incoming.toleranceMinutes,
      ),
      isDeleted: resolve('isDeleted', isDeleted, incoming.isDeleted),
      // Resolved under the same 'isDeleted' timestamp so it always tracks
      // whichever side's isDeleted value wins, never possible to disagree.
      deletedAt: resolve('isDeleted', deletedAt, incoming.deletedAt),
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
      // Day-state timestamps are owned by the caluclation and logic explained above
      // we dont want the per-field resolving to pull each one in independently, would break the logic from before
      if (dayStateKeys.contains(key)) continue;

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

  static List<HealthSessionDetail> _parseHealthSessions(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map(
          (entry) =>
              HealthSessionDetail.fromMap(Map<String, dynamic>.from(entry)),
        )
        .toList();
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

  static String? _serializeHealthMetricType(HealthMetricType? type) {
    return type?.name;
  }

  // Backup files (.habitt/.habittd) serialize this enum by name — a backup
  // written before exerciseMinutes/mindfulMinutes were renamed to workouts/
  // mindfulness would otherwise silently unlink the habit from Health on
  // restore, since no current member's `.name` would match the old string.
  static const Map<String, String> _legacyHealthMetricNames = {
    'exerciseMinutes': 'workouts',
    'mindfulMinutes': 'mindfulness',
  };

  static HealthMetricType? _deserializeHealthMetricType(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final resolved = _legacyHealthMetricNames[value] ?? value;
    for (final type in HealthMetricType.values) {
      if (type.name == resolved) {
        return type;
      }
    }

    return null;
  }

  static HealthWorkoutType? _deserializeHealthWorkoutType(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final type in HealthWorkoutType.values) {
      if (type.name == value) {
        return type;
      }
    }

    return null;
  }

  static HabitTrackingType? _inferTrackingType({
    required int amount,
    required int duration,
    HealthMetricType? healthMetric,
  }) {
    // amount/duration alone can't distinguish an amount goal from a
    // timeOfDay target (both just store a positive int in `amount`) — the
    // only reliable signal is the linked Health metric, so check it first.
    if (healthMetric == HealthMetricType.bedtime ||
        healthMetric == HealthMetricType.wakeTime) {
      return HabitTrackingType.timeOfDay;
    }

    if (amount >= 1) {
      return HabitTrackingType.amount;
    }

    if (duration > 0) {
      return HabitTrackingType.duration;
    }

    return null;
  }
}
