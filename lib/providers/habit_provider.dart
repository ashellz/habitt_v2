import 'package:flutter/material.dart';
import 'package:habitt/models/day.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/backup_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/util/check_reorder_categories.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HabitProvider extends ChangeNotifier {
  List<Habit> habits = [];
  List<Habit> todaysHabits = [];

  DateTime? _dateJoined;
  DateTime get dateJoined => _dateJoined ?? DateTime.now();
  final habitBox = Hive.box<Habit>('habits');
  final daysBox = Hive.box<Day>('days');
  DateTime? selectedDate;

  void setSelectedDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void clearSelectedDate() {
    selectedDate = null;
    notifyListeners();
  }

  StatsProvider? statsProvider;
  HabitStatsProvider? habitStatsProvider;
  BackupProvider? backupProvider;

  HabitProvider({this.statsProvider}) {
    init();
  }

  // Method to be called by the ProxyProvider's update callback
  void updateDependencies(StatsProvider newStatsProvider) {
    // Only update and notify if the instance has actually changed
    if (statsProvider != newStatsProvider) {
      statsProvider = newStatsProvider;
      // Add any logic that needs to run when the dependency is updated.
      // For example, re-fetching habits that depend on stats.
      // Then, notify listeners that this provider's data has changed.
      notifyListeners();
    }
  }

  void attachBackupProvider(BackupProvider provider) {
    backupProvider = provider;
  }

  void attachHabitStatsProvider(HabitStatsProvider provider) {
    habitStatsProvider = provider;
  }

  Future<void> init() async {
    await _loadHabits();
    refreshTodaysHabits(notify: false);
    _fillToday();
    _loadDateJoined();
  }

  Future<void> _loadDateJoined() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString('dateJoined');
    if (dateString != null) {
      _dateJoined = DateTime.parse(dateString);
    } else {
      _dateJoined = DateTime.now();
      prefs.setString("dateJoined", _dateJoined.toString());
    }
    notifyListeners();
  }

  Future<void> importDateJoined(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    if (_dateJoined == null || date.isBefore(_dateJoined!)) {
      _dateJoined = date;
      prefs.setString("dateJoined", _dateJoined.toString());
    }

    notifyListeners();
  }

  Future<void> _loadHabits() async {
    habits = habitBox.values.toList();
    await _normalizeHabitOrders();
    _sortHabitsByCategoryAndOrder(habits);
    await _hydrateHabitCreatedAtFallbacks();
    /*
    bool checkCategory(int category) {
      return category == 1 || category == 2 || category == 3 || category == 4;
    }

    // Deletes all habits which category isnt 1,2,3 or 4
    habits.removeWhere((habit) => !checkCategory(habit.categoryId));

    // Also delete all of those habits from the database
    for (final habit in habitBox.values) {
      if (!checkCategory(habit.categoryId)) {
        await habit.delete();
      }
    }

    // Also delete from the days database
    for (final day in daysBox.values) {
      day.habits.removeWhere((habit) => !checkCategory(habit.categoryId));
    }*/
  }

  Future<void> _hydrateHabitCreatedAtFallbacks() async {
    final now = DateTime.now().toUtc();

    for (final habit in habits) {
      DateTime? oldestDay;
      for (final day in daysBox.values) {
        final hasHabit = day.habits.any((h) => h.id == habit.id);
        if (!hasHabit) {
          continue;
        }

        final normalizedDay = _normalizeDate(day.date);
        if (oldestDay == null || normalizedDay.isBefore(oldestDay)) {
          oldestDay = normalizedDay;
        }
      }

      final normalizedCreatedAt = _normalizeDate(habit.createdAt);
      final resolvedCreatedAt = oldestDay ?? normalizedCreatedAt;

      if (!resolvedCreatedAt.isBefore(normalizedCreatedAt)) {
        continue;
      }

      habit.createdAt = resolvedCreatedAt.toUtc();
      habit.timestamps['createdAt'] = now;
      if (habit.isInBox) {
        await habit.save();
      }
    }
  }

  // Normalizing a datetime to be shorter so they can compare and be the same
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Function to check what week a date is in
  int _weekKey(DateTime date) {
    final normalized = _normalizeDate(date);
    final monday = normalized.subtract(Duration(days: normalized.weekday - 1));
    final startOfYear = DateTime(monday.year, 1, 1);
    final dayOfYear = monday.difference(startOfYear).inDays + 1;
    return (monday.year * 1000) + dayOfYear;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    return _weekKey(a) == _weekKey(b);
  }

  // Checks how many times a habit has been completed in the current week
  // Used for deterining if a habit with weekly schedule appears on a day
  int _effectiveTimesCompletedThisWeek(Habit habit, DateTime day) {
    final ts = habit.timestamps['timesCompletedThisWeek'];
    if (ts == null) return habit.timesCompletedThisWeek;
    return _weekKey(ts) == _weekKey(day) ? habit.timesCompletedThisWeek : 0;
  }

  // Checks how many times a habit has been completed in the current month
  // Used for deterining if a habit with monthly schedule appears on a day
  int _effectiveTimesCompletedThisMonth(Habit habit, DateTime day) {
    final ts = habit.timestamps['timesCompletedThisMonth'];
    if (ts == null) return habit.timesCompletedThisMonth;
    return _isSameMonth(ts, day) ? habit.timesCompletedThisMonth : 0;
  }

  // Used for building the dates when habit should appear for a habit with custom schedule
  List<String> _buildCustomAppearance({
    required DateTime anchor,
    required int intervalDays,
  }) {
    final normalizedAnchor = _normalizeDate(anchor);
    final value = intervalDays.clamp(1, 365);
    final output = <String>[];
    for (int i = 0; i < 365; i += value) {
      // Starting from the current day (anchor date), add dates to the appearance list based on the custom interval until we have a full year of appearances
      output.add(
        normalizedAnchor
            .add(Duration(days: i))
            .toIso8601String()
            .split('T')
            .first,
      );
    }
    return output;
  }

  // Ensures that a habit with custom schedule has its customAppearance list updated with future dates if needed
  void _ensureCustomAppearance(Habit habit, DateTime day) {
    final now = DateTime.now().toUtc();
    final normalizedDay = _normalizeDate(day);

    // If custom schedule settings arent empty
    if (habit.customAppearance.isNotEmpty && habit.lastCustomUpdate != null) {
      final latest = DateTime.tryParse(habit.customAppearance.last);
      // If the latest scheduled appearance is after the day we are checking, then we dont need to update the schedule appearances yet
      if (latest != null && !normalizedDay.isAfter(latest)) {
        return;
      }
    }

    // If last update is null then we go from today (the given date), otherwise from the last update
    final anchor =
        habit.lastCustomUpdate == null
            ? normalizedDay
            : _normalizeDate(habit.lastCustomUpdate!);

    // Updating habit data
    habit.customAppearance = _buildCustomAppearance(
      anchor: anchor,
      intervalDays: habit.customIntervalDays,
    );
    habit.lastCustomUpdate = now;
    habit.timestamps['customAppearance'] = now;
    habit.timestamps['lastCustomUpdate'] = now;
  }

  // Here we check if a habit appears on a given day
  bool _appearsOnDay(Habit habit, DateTime day) {
    final normalizedDay = _normalizeDate(day);
    switch (habit.scheduleType) {
      case ScheduleType.daily:
        return true;
      case ScheduleType.weekly:
        if (habit.selectedDaysAWeek.isNotEmpty) {
          return habit.selectedDaysAWeek.contains(normalizedDay.weekday);
        }
        final weeklyCount = _effectiveTimesCompletedThisWeek(
          habit,
          normalizedDay,
        );
        return weeklyCount < habit.weeklyTarget;
      case ScheduleType.monthly:
        if (habit.selectedDaysAMonth.isNotEmpty) {
          return habit.selectedDaysAMonth.contains(normalizedDay.day);
        }
        final monthlyCount = _effectiveTimesCompletedThisMonth(
          habit,
          normalizedDay,
        );
        return monthlyCount < habit.monthlyTarget;
      case ScheduleType.custom:
        _ensureCustomAppearance(habit, normalizedDay);
        final key = normalizedDay.toIso8601String().split('T').first;
        return habit.customAppearance.contains(key);
    }
  }

  bool appearsOnDay(Habit habit, DateTime day) {
    return _appearsOnDay(habit, day);
  }

  // Function to filter habits for a specific day based on their schedule and completion status
  List<Habit> _filteredHabitsForDay(DateTime day, List<Habit> source) {
    return source
        .where((habit) => _appearsOnDay(habit, day) || habit.completed)
        .toList();
  }

  int _compareHabitsByOrder(Habit a, Habit b) {
    final categoryCompare = a.categoryId.compareTo(b.categoryId);
    if (categoryCompare != 0) {
      return categoryCompare;
    }

    final aOrder = a.order <= 0 ? 1 << 30 : a.order;
    final bOrder = b.order <= 0 ? 1 << 30 : b.order;
    final orderCompare = aOrder.compareTo(bOrder);
    if (orderCompare != 0) {
      return orderCompare;
    }

    return a.id.compareTo(b.id);
  }

  void _sortHabitsByCategoryAndOrder(List<Habit> source) {
    source.sort(_compareHabitsByOrder);
  }

  int _nextOrderForCategory(int categoryId) {
    int maxOrder = 0;
    for (final habit in habits) {
      if (habit.categoryId != categoryId) {
        continue;
      }
      if (habit.order > maxOrder) {
        maxOrder = habit.order;
      }
    }
    return maxOrder + 1;
  }

  Future<void> _normalizeHabitOrders() async {
    if (habits.isEmpty) {
      return;
    }

    final habitsByCategory = <int, List<Habit>>{};
    for (final habit in habits) {
      habitsByCategory.putIfAbsent(habit.categoryId, () => []).add(habit);
    }

    final now = DateTime.now().toUtc();

    for (final entry in habitsByCategory.entries) {
      final categoryHabits = entry.value;
      categoryHabits.sort((a, b) {
        final aOrder = a.order <= 0 ? 1 << 30 : a.order;
        final bOrder = b.order <= 0 ? 1 << 30 : b.order;
        final orderCompare = aOrder.compareTo(bOrder);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return a.id.compareTo(b.id);
      });

      for (int index = 0; index < categoryHabits.length; index++) {
        final desiredOrder = index + 1;
        final habit = categoryHabits[index];
        if (habit.order == desiredOrder) {
          continue;
        }

        habit.order = desiredOrder;
        habit.timestamps['order'] = now;
        if (habit.isInBox) {
          await habit.save();
        }
      }
    }
  }

  // Getting habits for a certain day with extra logic
  List<Habit> getHabitsForDate(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    final today = _normalizeDate(DateTime.now());
    if (normalizedDay == today) {
      return List<Habit>.from(todaysHabits);
    }
    return getHabitsFromDay(normalizedDay);
  }

  // Refreshing todays habits
  void refreshTodaysHabits({bool notify = true}) {
    final today = _normalizeDate(DateTime.now());
    todaysHabits = _filteredHabitsForDay(today, habits);
    _sortHabitsByCategoryAndOrder(todaysHabits);
    if (notify) {
      notifyListeners();
    }
  }

  void _fillToday() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final todayKey = today.toIso8601String().split('T').first;

    final todayEntry = daysBox.get(todayKey);

    if (todayEntry == null) {
      debugPrint("Creating new day entry");
      daysBox.put(
        todayKey,
        Day(
          date: today,
          habits: _filteredHabitsForDay(today, habits),
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }
  }

  bool _isDayFullyCompleted(DateTime day) {
    final normalizedDay = _normalizeDate(day);
    final dayHabits = getHabitsFromDay(normalizedDay, hydrateMissing: true);

    int requiredHabits = 0;
    int satisfiedHabits = 0;

    for (final habit in dayHabits) {
      if (habit.optional) {
        continue;
      }

      requiredHabits++;
      if (habit.completed || habit.skipped) {
        satisfiedHabits++;
      }
    }

    return requiredHabits > 0 && satisfiedHabits >= requiredHabits;
  }

  void _refreshPerfectStreakForDayIfNeeded(DateTime day) {
    if (statsProvider == null) {
      return;
    }

    // Always recompute after a completion-state transition. This keeps the
    // streak correct when a day becomes perfect and when it loses perfection.
    _isDayFullyCompleted(day);

    statsProvider!.perfectDaysStreak = statsProvider!.refreshPerfectStreak();
  }

  Map<DateTime, double> getThisWeekProgress({DateTime? anchorDate}) {
    final baseDate = _normalizeDate(anchorDate ?? DateTime.now());
    final startOfWeek = baseDate.subtract(Duration(days: baseDate.weekday - 1));

    debugPrint(
      "Calculating week progress. Start of week: $startOfWeek, Anchor: $baseDate",
    );

    List<Day> thisWeekDays = [];

    for (int i = 0; i < 7; i++) {
      thisWeekDays.add(
        Day(
          date: startOfWeek.add(Duration(days: i)),
          habits: getHabitsFromDay(startOfWeek.add(Duration(days: i))),
          timestamp: DateTime.now().toUtc(),
        ),
      );

      debugPrint(
        "Day: ${thisWeekDays[i].date}, Habits: ${thisWeekDays[i].habits.length}",
      );
    }

    debugPrint("This week days: $thisWeekDays");

    // Calculating progress for each day 0 - 1

    final Map<DateTime, double> daysProgress = {};

    for (final day in thisWeekDays) {
      final totalHabits = day.habits.isEmpty ? 1 : day.habits.length;
      final completedWeight = day.habits.fold<double>(0.0, (sum, habit) {
        if (habit.completed) {
          return sum + 1.0;
        }

        if (habit.tracksAmount) {
          if (habit.amount <= 0) {
            return sum;
          }
          return sum + (habit.amountCompleted / habit.amount).clamp(0.0, 1.0);
        }

        if (habit.tracksDuration) {
          if (habit.duration <= 0) {
            return sum;
          }
          return sum +
              (habit.durationCompleted / habit.duration).clamp(0.0, 1.0);
        }

        return sum;
      });

      daysProgress[day.date] = (completedWeight / totalHabits).clamp(0.0, 1.0);
    }

    debugPrint("Returning Days progress: $daysProgress");
    return daysProgress;
  }

  Future<void> updateHabitInDB(Habit habit, {DateTime? day}) async {
    debugPrint("Updating habit in DB: $habit");
    habitStatsProvider?.invalidateHabit(habit.id);
    if (statsProvider != null) {
      statsProvider!.addShouldRefresh(StatsType.habitsCompleted);
    }

    DateTime usedDay =
        day ??
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Trying to get the real, saved habit from habitBox using the ID
    final realHabit = habitBox.values.firstWhere(
      (h) => h.id == habit.id,
      orElse: () => habit, // fallback to current one if not found
    );

    // Only save if habit is in box (not a detached copy)
    if (realHabit.isInBox) {
      await realHabit.save();
    } else {
      debugPrint("Habit is not in a box, skipping save()");
    }

    // Schedule auto-sync after habit modification
    backupProvider?.scheduleAutoSync();

    final dayKey = usedDay.toIso8601String().split('T').first;
    final dayEntry = daysBox.get(dayKey);

    if (dayEntry != null) {
      final index = dayEntry.habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        dayEntry.habits[index] = habit; // still use passed-in habit copy
        await dayEntry.save();
      } else {
        debugPrint("Habit not found in day entry");
        dayEntry.habits.add(habit);
        await dayEntry.save();
      }
    } else {
      debugPrint("Day entry is null");
      saveHabitDay(usedDay);
    }
  }

  // Function used to get list of habits from a specific day from database
  List<Habit> getHabitsFromDay(DateTime day, {bool hydrateMissing = false}) {
    final normalizedDay = _normalizeDate(day);
    final today = _normalizeDate(DateTime.now());
    if (normalizedDay == today) {
      return List<Habit>.from(todaysHabits);
    }

    final dayKey = normalizedDay.toIso8601String().split('T').first;
    Day? dayEntry = daysBox.get(dayKey);
    List<Habit> dayHabits = dayEntry?.habits ?? [];

    // Optionally hydrate missing days (only when explicitly requested)
    if (hydrateMissing &&
        dayHabits.isEmpty &&
        normalizedDay.isBefore(today) &&
        (_dateJoined == null || normalizedDay.isAfter(_dateJoined!)) &&
        habits.isNotEmpty) {
      saveHabitDay(normalizedDay, resetCompletion: true);
      dayEntry = daysBox.get(dayKey);
      dayHabits = dayEntry?.habits ?? [];
    }

    final filteredHabits = _filteredHabitsForDay(normalizedDay, dayHabits);
    _sortHabitsByCategoryAndOrder(filteredHabits);
    return filteredHabits;
  }

  void addHabit(Habit habit) {
    if (statsProvider != null) {
      statsProvider!.addShouldRefresh(StatsType.highestAmountOfHabitsLastWeek);
    }

    if (habit.order <= 0) {
      habit.order = _nextOrderForCategory(habit.categoryId);
      habit.timestamps['order'] = DateTime.now().toUtc();
    }

    habits.add(habit);
    habitStatsProvider?.invalidateHabit(habit.id);
    _sortHabitsByCategoryAndOrder(habits);
    habitBox.add(habit);
    updateHabitInDB(habit);
    refreshTodaysHabits(notify: false);

    notifyListeners();
  }

  Future<void> reorderHabitsInCategory({
    required int categoryId,
    required int oldIndex,
    required int newIndex,
    required bool todaysOnly,
  }) async {
    if (oldIndex < 0 || newIndex < 0 || oldIndex == newIndex) {
      return;
    }

    final categoryHabits =
        habits.where((h) => h.categoryId == categoryId).toList();
    if (categoryHabits.length < 2) {
      return;
    }

    categoryHabits.sort((a, b) {
      final aOrder = a.order <= 0 ? 1 << 30 : a.order;
      final bOrder = b.order <= 0 ? 1 << 30 : b.order;
      final orderCompare = aOrder.compareTo(bOrder);
      if (orderCompare != 0) {
        return orderCompare;
      }
      return a.id.compareTo(b.id);
    });

    late final List<Habit> reorderedCategory;

    if (!todaysOnly) {
      if (oldIndex >= categoryHabits.length ||
          newIndex >= categoryHabits.length) {
        return;
      }

      reorderedCategory = List<Habit>.from(categoryHabits);
      final moved = reorderedCategory.removeAt(oldIndex);
      reorderedCategory.insert(newIndex, moved);
    } else {
      final scheduledCategoryHabits =
          todaysHabits.where((h) => h.categoryId == categoryId).toList();
      if (oldIndex >= scheduledCategoryHabits.length ||
          newIndex >= scheduledCategoryHabits.length ||
          scheduledCategoryHabits.length < 2) {
        return;
      }

      final reorderedScheduled = List<Habit>.from(scheduledCategoryHabits);
      final movedScheduled = reorderedScheduled.removeAt(oldIndex);
      reorderedScheduled.insert(newIndex, movedScheduled);

      final scheduledIdSet = scheduledCategoryHabits.map((h) => h.id).toSet();
      int scheduledCursor = 0;
      reorderedCategory = [];

      for (final habit in categoryHabits) {
        if (!scheduledIdSet.contains(habit.id)) {
          reorderedCategory.add(habit);
          continue;
        }

        reorderedCategory.add(reorderedScheduled[scheduledCursor]);
        scheduledCursor += 1;
      }
    }

    final now = DateTime.now().toUtc();
    final changedHabits = <Habit>[];

    for (int index = 0; index < reorderedCategory.length; index++) {
      final habit = reorderedCategory[index];
      final desiredOrder = index + 1;
      if (habit.order == desiredOrder) {
        continue;
      }

      habit.order = desiredOrder;
      habit.timestamps['order'] = now;
      changedHabits.add(habit);
    }

    _sortHabitsByCategoryAndOrder(habits);
    refreshTodaysHabits(notify: false);
    notifyListeners();

    for (final habit in changedHabits) {
      if (habit.isInBox) {
        await habit.save();
      }
    }

    backupProvider?.scheduleAutoSync();
  }

  void removeHabit(Habit habit, BuildContext context) async {
    if (statsProvider != null) {
      statsProvider!.addShouldRefresh(StatsType.highestAmountOfHabitsLastWeek);
    }

    habits.removeWhere((h) => h.id == habit.id);
    habitStatsProvider?.removeHabit(habit.id);
    await habit.deleteHabit();
    if (context.mounted) checkReorderCategories(context, habit);

    updateHabitInDB(habit);
    refreshTodaysHabits(notify: false);
    notifyListeners();
  }

  void completeHabit(
    int id,
    BuildContext context,
    StateProvider stateProvider, {
    DateTime? dayOverride,
  }) async {
    late Habit habit;

    final today = DateTime.now();
    final _selectedDate = dayOverride ?? selectedDate ?? today;
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      final List<Habit> dayHabits = getHabitsFromDay(
        daySimple,
        hydrateMissing: true,
      );
      habit = dayHabits.firstWhere((h) => h.id == id);
      if (!stateProvider.shouldUpdateStreaks) {
        stateProvider.shouldUpdateStreaks = true;
      }
    }

    debugPrint("Completing habit: $id, day: $daySimple");
    habitStatsProvider?.invalidateHabit(id);
    final wasCompleted = habit.completed;
    await habit.completeHabit();
    debugPrint("Habit completed: ${habit.completed}");
    final currentHabit = habits.firstWhere((h) => h.id == id);
    // Check if habit is within the current week or month dependng on scheudle tpye
    final shouldAffectCurrentPeriod =
        (currentHabit.scheduleType == ScheduleType.weekly &&
            _isSameWeek(daySimple, todaySimple)) ||
        (currentHabit.scheduleType == ScheduleType.monthly &&
            _isSameMonth(daySimple, todaySimple));

    if (shouldAffectCurrentPeriod) {
      // If it affects current period we update habit schedule counters
      final weeklyBaseCount =
          currentHabit.scheduleType == ScheduleType.weekly
              ? _effectiveTimesCompletedThisWeek(currentHabit, daySimple)
              : null;
      final monthlyBaseCount =
          currentHabit.scheduleType == ScheduleType.monthly
              ? _effectiveTimesCompletedThisMonth(currentHabit, daySimple)
              : null;

      currentHabit.updateScheduleCountersOnCompletionToggle(
        wasCompleted: wasCompleted,
        isCompleted: habit.completed,
        weeklyBaseCount: weeklyBaseCount,
        monthlyBaseCount: monthlyBaseCount,
      );
    }
    if (context.mounted && daySimple == todaySimple) {
      // Reordering categories if today
      checkReorderCategories(context, habit);
    }

    await updateHabitInDB(habit, day: daySimple);
    _refreshPerfectStreakForDayIfNeeded(daySimple);
    refreshTodaysHabits(notify: false);
    notifyListeners();
  }

  void skipHabit(
    int id,
    BuildContext context,
    StateProvider stateProvider, {
    required DateTime day,
  }) async {
    debugPrint("Skipping habit: $id");
    habitStatsProvider?.invalidateHabit(id);
    late Habit habit;
    Habit? habitDayBefore;

    final today = DateTime.now();
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(day.year, day.month, day.day);
    final dayBefore = daySimple.subtract(const Duration(days: 1));

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      final List<Habit> dayHabits = getHabitsFromDay(day, hydrateMissing: true);
      habit = dayHabits.firstWhere((h) => h.id == id);
      if (!stateProvider.shouldUpdateStreaks) {
        stateProvider.shouldUpdateStreaks = true;
      }
    }

    final List<Habit> dayBeforeHabits = getHabitsFromDay(dayBefore);
    if (dayBeforeHabits.isNotEmpty) {
      habitDayBefore = dayBeforeHabits.firstWhere((h) => h.id == id);
    }

    if (habitDayBefore != null && habitDayBefore.skipped) {
      debugPrint("Skipping habit not allowed, habit day before skipped");
      return;
    }

    await habit.skipHabit();
    if (context.mounted && daySimple == todaySimple) {
      checkReorderCategories(context, habit);
    }
    updateHabitInDB(habit, day: day);
    refreshTodaysHabits(notify: false);
    notifyListeners();
  }

  void updateHabit(Habit habit) {
    habitStatsProvider?.invalidateHabit(habit.id);
    habits.where((h) => h.id == habit.id).first.updateHabit(habit);
    updateHabitInDB(habit);
    refreshTodaysHabits(notify: false);

    notifyListeners();
  }

  void resetCompletion() async {
    habitStatsProvider?.clearAll();
    for (final habit in habits) {
      await habit.resetCompletion();
      await updateHabitInDB(habit);
    }
    refreshTodaysHabits(notify: false);
    notifyListeners();
  }

  void updateHabitAmountCompleted(
    int id,
    int amountCompleted,
    BuildContext context, {
    DateTime? dayOverride,
  }) async {
    habitStatsProvider?.invalidateHabit(id);
    late Habit habit;

    final today = DateTime.now();
    final _selectedDate = dayOverride ?? selectedDate ?? today;
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      final List<Habit> dayHabits = getHabitsFromDay(
        daySimple,
        hydrateMissing: true,
      );
      habit = dayHabits.firstWhere((h) => h.id == id);
    }

    habit.updateHabitAmountCompleted(amountCompleted);
    if (context.mounted) checkReorderCategories(context, habit);

    await updateHabitInDB(habits.firstWhere((h) => h.id == id));
    _refreshPerfectStreakForDayIfNeeded(daySimple);
    refreshTodaysHabits(notify: false);
    notifyListeners();
  }

  void updateHabitDurationCompleted(
    int id,
    int durationCompleted,
    BuildContext context, {
    DateTime? dayOverride,
  }) async {
    habitStatsProvider?.invalidateHabit(id);
    late Habit habit;

    final today = DateTime.now();
    final _selectedDate = dayOverride ?? selectedDate ?? today;
    final todaySimple = DateTime(today.year, today.month, today.day);
    final daySimple = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (daySimple == todaySimple) {
      habit = habits.firstWhere((h) => h.id == id);
    } else {
      final List<Habit> dayHabits = getHabitsFromDay(
        daySimple,
        hydrateMissing: true,
      );
      habit = dayHabits.firstWhere((h) => h.id == id);
    }

    habit.updateHabitDurationCompleted(durationCompleted);

    if (context.mounted) checkReorderCategories(context, habit);

    await updateHabitInDB(habits.firstWhere((h) => h.id == id));
    _refreshPerfectStreakForDayIfNeeded(daySimple);
    refreshTodaysHabits(notify: false);
    notifyListeners();
  }

  Future<void> saveHabitDay(
    DateTime day, {
    bool resetCompletion = false,
  }) async {
    habitStatsProvider?.clearAll();
    final daySimple = DateTime(day.year, day.month, day.day);
    final String dayKey = daySimple.toIso8601String().split('T').first;
    debugPrint("Saving day at: $daySimple");

    late final List<Habit> clonedHabits;

    if (resetCompletion) {
      clonedHabits = habits.map((h) => h.copyResetCompletion()).toList();
    } else {
      clonedHabits = habits.map((h) => h.copy()).toList();
    }

    final scheduledForDay = _filteredHabitsForDay(daySimple, clonedHabits);

    daysBox.put(
      dayKey,
      Day(
        date: daySimple,
        habits: scheduledForDay,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> assignStreaks() async {
    debugPrint("Assigning streaks");

    final sortedDays = daysBox.values.toList();
    // Getting all days from the database and sorting them from newest to oldest
    sortedDays.sort((a, b) => b.date.compareTo(a.date));

    final today = _normalizeDate(DateTime.now());
    // Removing today
    sortedDays.removeWhere((day) => _normalizeDate(day.date) == today);

    final currentHabits = habitBox.values;

    for (final habit in currentHabits) {
      debugPrint("Checking habit: ${habit.name}");

      int streak = 0;
      int longestStreak = habit.longestStreak;
      int consecutiveMisses = 0;

      for (final day in sortedDays) {
        final normalizedDay = _normalizeDate(day.date);

        if (!_appearsOnDay(habit, normalizedDay)) {
          // If it doenst appear on this day, we skip it, it doesnt affect the streak
          continue;
        }

        Habit? dayHabit;
        // We get the correct habit
        for (final candidate in day.habits) {
          if (candidate.id == habit.id) {
            dayHabit = candidate;
            break;
          }
        }

        if (dayHabit == null) {
          continue;
        }

        // If it's completed we reset misses counter and increase streak
        if (dayHabit.completed) {
          streak++;
          consecutiveMisses = 0;
          if (streak > longestStreak) {
            longestStreak = streak;
          }
        } else {
          // If not completed we increment misses counter

          consecutiveMisses++;
          if (consecutiveMisses >= 2) {
            // If there are 2 or more consecutive misses, we break the loop
            break;
          }
        }
      }

      habit.updateStreak(streak: streak, longestStreak: longestStreak);
      debugPrint("Streak: $streak, Longest Streak: $longestStreak");
      await habit.save();
    }

    notifyListeners();
  }
}
