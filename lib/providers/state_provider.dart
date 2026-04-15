import 'package:flutter/material.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/models/habit_notification_time.dart';
import 'package:habitt/models/premade_habit_template.dart';
import 'package:habitt/models/premade_habit_type.dart';
import 'package:habitt/models/schedule_type.dart';
import 'package:habitt/providers/theme_provider.dart';
import 'package:habitt/services/old_color_service.dart';
import 'package:habitt/services/emoji_service.dart';
import 'package:habitt/util/amount_label_preset.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinycolor2/tinycolor2.dart';

class StateProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _shouldUpdateStreaks = false;
  static const String _amountLabelsPrefsKey = 'amount_labels';
  List<String> _customAmountLabels = [];

  StateProvider(SharedPreferences prefs) {
    _prefs = prefs;
    init();
  }

  void init() {
    _shouldUpdateStreaks = _prefs?.getBool('shouldUpdateStreaks') ?? false;
    _loadAmountLabels();
    notifyListeners();
  }

  List<String> get defaultAmountLabels => AmountLabelPreset.defaultLabels;

  List<String> get customAmountLabels => List<String>.from(_customAmountLabels);

  List<String> get allAmountLabels {
    final labels = <String>[];

    for (final label in AmountLabelPreset.defaultLabels) {
      if (!labels.contains(label)) {
        labels.add(label);
      }
    }

    for (final label in _customAmountLabels) {
      if (!labels.contains(label)) {
        labels.add(label);
      }
    }

    return labels;
  }

  String normalizeAmountLabel(String value) {
    return value.trim().toLowerCase();
  }

  String canonicalizeAmountLabel(String value) {
    return AmountLabelPreset.canonicalize(value);
  }

  bool addCustomAmountLabel(String value) {
    final normalized = canonicalizeAmountLabel(value);
    if (normalized.isEmpty) {
      return false;
    }

    if (AmountLabelPreset.isPredefinedLabel(normalized) ||
        _customAmountLabels.contains(normalized)) {
      return false;
    }

    _customAmountLabels = [..._customAmountLabels, normalized];
    _prefs?.setStringList(_amountLabelsPrefsKey, _customAmountLabels);
    notifyListeners();
    return true;
  }

  void _loadAmountLabels() {
    final stored = _prefs?.getStringList(_amountLabelsPrefsKey) ?? [];
    final normalized = <String>[];

    for (final value in stored) {
      final label = canonicalizeAmountLabel(value);
      if (label.isEmpty || AmountLabelPreset.isPredefinedLabel(label)) {
        continue;
      }
      if (!normalized.contains(label)) {
        normalized.add(label);
      }
    }

    _customAmountLabels = normalized;
  }

  bool _showAllHabits = true;

  bool get showAllHabits => _showAllHabits;

  void toggleShowAllHabits() {
    _showAllHabits = !_showAllHabits;
    notifyListeners();
  }

  int _selectedHabitId = -1;

  int _habitCategoryId = 1;
  int _habitAmount = 0;
  Duration _habitDuration = Duration.zero;
  HabitTrackingType? _selectedHabitTrackingType;
  TextEditingController habitAmountLabelController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  String _iconPath = "";
  bool _isOptional = false;
  Color? _habitColor;
  String? _habitColorName;
  ScheduleType _selectedScheduleOption = ScheduleType.daily;
  int _weeklyTarget = 1;
  int _monthlyTarget = 1;
  int _customIntervalDays = 2;
  final Set<int> _selectedDaysAWeek = <int>{};
  final Set<int> _selectedDaysAMonth = <int>{};
  PremadeHabitType? _selectedPremadeHabitType;

  String _alertText = "";
  bool _showAlert = false;

  String get alertText => _alertText;
  bool get showAlert => _showAlert;
  ScheduleType get selectedScheduleOption => _selectedScheduleOption;
  int get weeklyTarget => _weeklyTarget;
  int get monthlyTarget => _monthlyTarget;
  int get customIntervalDays => _customIntervalDays;
  Set<int> get selectedDaysAWeek => Set<int>.from(_selectedDaysAWeek);
  Set<int> get selectedDaysAMonth => Set<int>.from(_selectedDaysAMonth);
  PremadeHabitType? get selectedPremadeHabitType => _selectedPremadeHabitType;
  HabitTrackingType? get selectedHabitTrackingType =>
      _selectedHabitTrackingType;

  String get scheduleSummary {
    switch (_selectedScheduleOption) {
      case ScheduleType.daily:
        return 'Daily';
      case ScheduleType.weekly:
        return 'Weekly';
      case ScheduleType.monthly:
        return 'Monthly';
      case ScheduleType.custom:
        return 'Custom';
    }
  }

  set selectedDaysAWeek(Set<int> days) {
    _selectedDaysAWeek
      ..clear()
      ..addAll(days.where((d) => d >= 1 && d <= 7));
    weeklyTarget =
        _selectedDaysAWeek.isNotEmpty ? _selectedDaysAWeek.length : 1;
    notifyListeners();
  }

  set selectedDaysAMonth(Set<int> days) {
    _selectedDaysAMonth
      ..clear()
      ..addAll(days.where((d) => d >= 1 && d <= 31));
    monthlyTarget =
        _selectedDaysAMonth.isNotEmpty ? _selectedDaysAMonth.length : 1;
    notifyListeners();
  }

  set selectedScheduleOption(ScheduleType option) {
    _selectedScheduleOption = option;
    notifyListeners();
  }

  set weeklyTarget(int value) {
    _weeklyTarget = value.clamp(1, 6);
    notifyListeners();
  }

  set monthlyTarget(int value) {
    _monthlyTarget = value.clamp(1, 30);
    notifyListeners();
  }

  set customIntervalDays(int value) {
    _customIntervalDays = value.clamp(1, 365);
    notifyListeners();
  }

  set selectedPremadeHabitType(PremadeHabitType? value) {
    _selectedPremadeHabitType = value;
    notifyListeners();
  }

  set selectedHabitTrackingType(HabitTrackingType? value) {
    _selectedHabitTrackingType = value;
    if (_selectedHabitTrackingType == HabitTrackingType.amount &&
        _habitAmount < 1) {
      _habitAmount = 1;
    }
    notifyListeners();
  }

  void clearSelectedPremadeHabitType() {
    _selectedPremadeHabitType = null;
    notifyListeners();
  }

  void applyPremadeHabitTemplate(
    PremadeHabitTemplate template, {
    bool overrideConfig = true,
  }) {
    _selectedPremadeHabitType = template.type;
    if (!overrideConfig) {
      notifyListeners();
      return;
    }
    _habitCategoryId = template.categoryId;

    nameController.text = template.name;
    descController.clear();
    _iconPath = template.iconPath;

    _habitAmount = template.amount;
    _habitDuration = Duration(minutes: template.durationMinutes);
    _selectedHabitTrackingType =
        template.amount >= 1
            ? HabitTrackingType.amount
            : template.durationMinutes > 0
            ? HabitTrackingType.duration
            : null;
    habitAmountLabelController.text = canonicalizeAmountLabel(
      template.amountLabel,
    );

    _isOptional = false;
    _timeIntervalEnabled = false;
    _timeIntervalStart = 420;
    _timeIntervalEnd = 450;
    _habitNotificationsEnabled = false;
    _habitNotificationTimes = _buildDefaultNotificationTimesForCategory(
      _habitCategoryId,
    );

    _habitColor = null;
    _habitColorName = null;

    _selectedScheduleOption = template.scheduleType;
    _weeklyTarget = template.weeklyTarget.clamp(1, 6);
    _monthlyTarget = template.monthlyTarget.clamp(1, 30);
    _customIntervalDays = template.customIntervalDays.clamp(1, 365);

    _selectedDaysAWeek
      ..clear()
      ..addAll(template.selectedDaysAWeek.where((d) => d >= 1 && d <= 7));
    _selectedDaysAMonth
      ..clear()
      ..addAll(template.selectedDaysAMonth.where((d) => d >= 1 && d <= 31));

    notifyListeners();
  }

  void toggleWeeklyDay(int weekday) {
    if (weekday < 1 || weekday > 7) return;
    if (_selectedDaysAWeek.contains(weekday)) {
      _selectedDaysAWeek.remove(weekday);
    } else {
      _selectedDaysAWeek.add(weekday);
    }
    weeklyTarget =
        _selectedDaysAWeek.isNotEmpty ? _selectedDaysAWeek.length : 1;
    notifyListeners();
  }

  void toggleMonthlyDay(int day) {
    if (day < 1 || day > 31) return;
    if (_selectedDaysAMonth.contains(day)) {
      _selectedDaysAMonth.remove(day);
    } else {
      _selectedDaysAMonth.add(day);
    }
    monthlyTarget =
        _selectedDaysAMonth.isNotEmpty ? _selectedDaysAMonth.length : 1;
    notifyListeners();
  }

  void setScheduleFromHabit({
    required ScheduleType scheduleType,
    required int weeklyTarget,
    required int monthlyTarget,
    required int customIntervalDays,
    required List<int> selectedDaysAWeek,
    required List<int> selectedDaysAMonth,
  }) {
    _selectedScheduleOption = scheduleType;
    _weeklyTarget = weeklyTarget.clamp(1, 6);
    _monthlyTarget = monthlyTarget.clamp(1, 30);
    _customIntervalDays = customIntervalDays.clamp(1, 365);
    _selectedDaysAWeek
      ..clear()
      ..addAll(selectedDaysAWeek.where((d) => d >= 1 && d <= 7));
    _selectedDaysAMonth
      ..clear()
      ..addAll(selectedDaysAMonth.where((d) => d >= 1 && d <= 31));
    notifyListeners();
  }

  set alertText(String value) {
    _alertText = value;
    notifyListeners();
  }

  void toggleAlert({bool? show}) {
    _showAlert = show ?? !_showAlert;
    notifyListeners();
  }

  bool _timeIntervalEnabled = false;
  int _timeIntervalStart = 420;
  int _timeIntervalEnd = 450;
  bool _habitNotificationsEnabled = false;
  List<HabitNotificationTime> _habitNotificationTimes = [
    HabitNotificationTime(
      id: DateTime.now().microsecondsSinceEpoch,
      minutesOfDay: 9 * 60,
    ),
  ];

  bool get timeIntervalEnabled => _timeIntervalEnabled;
  int get timeIntervalStart => _timeIntervalStart;
  int get timeIntervalEnd => _timeIntervalEnd;
  bool get habitNotificationsEnabled => _habitNotificationsEnabled;
  List<HabitNotificationTime> get habitNotificationTimes =>
      _habitNotificationTimes.map((slot) => slot.copy()).toList();

  set timeIntervalEnabled(bool value) {
    _timeIntervalEnabled = value;
    notifyListeners();
  }

  set timeIntervalStart(int value) {
    _timeIntervalStart = value;
    notifyListeners();
  }

  set timeIntervalEnd(int value) {
    _timeIntervalEnd = value;
    notifyListeners();
  }

  set habitNotificationsEnabled(bool value) {
    _habitNotificationsEnabled = value;
    notifyListeners();
  }

  void setNotificationsFromHabit({
    required bool enabled,
    required List<HabitNotificationTime> notificationTimes,
  }) {
    _habitNotificationsEnabled = enabled;
    if (notificationTimes.isEmpty) {
      _habitNotificationTimes = _buildDefaultNotificationTimesForCategory(
        _habitCategoryId,
      );
    } else {
      _habitNotificationTimes =
          notificationTimes.map((slot) => slot.copy()).toList();
    }
    notifyListeners();
  }

  void addHabitNotificationTime({int? minutesOfDay}) {
    final defaultMinutesOfDay = _getDefaultNotificationTimeForCategory(
      _habitCategoryId,
    );
    _habitNotificationTimes = [
      ..._habitNotificationTimes,
      HabitNotificationTime(
        id: DateTime.now().microsecondsSinceEpoch,
        minutesOfDay: (minutesOfDay ?? defaultMinutesOfDay).clamp(
          0,
          (24 * 60) - 1,
        ),
      ),
    ];
    notifyListeners();
  }

  void updateHabitNotificationTime(int id, int minutesOfDay) {
    _habitNotificationTimes =
        _habitNotificationTimes
            .map(
              (slot) =>
                  slot.id == id
                      ? HabitNotificationTime(
                        id: slot.id,
                        minutesOfDay: minutesOfDay.clamp(0, (24 * 60) - 1),
                      )
                      : slot,
            )
            .toList();
    notifyListeners();
  }

  void removeHabitNotificationTime(int id) {
    if (_habitNotificationTimes.length <= 1) {
      return;
    }
    _habitNotificationTimes =
        _habitNotificationTimes.where((slot) => slot.id != id).toList();
    notifyListeners();
  }

  bool get shouldUpdateStreaks => _shouldUpdateStreaks;

  set shouldUpdateStreaks(bool value) {
    _shouldUpdateStreaks = value;
    _prefs?.setBool('shouldUpdateStreaks', value);
    notifyListeners();
  }

  toggleOptional() {
    _isOptional = !_isOptional;
    notifyListeners();
  }

  set isOptional(bool value) {
    _isOptional = value;
    notifyListeners();
  }

  set iconPath(String newPath) {
    if (_iconPath != newPath) {
      Future.delayed(Duration(milliseconds: 150)).then((value) {
        _iconPath = newPath;
        notifyListeners();
      });
    }
  }

  void setIconPathImmediately(String newPath) {
    if (_iconPath == newPath) {
      return;
    }
    _iconPath = newPath;
    notifyListeners();
  }

  set selectedHabitId(int id) {
    _selectedHabitId = id;
    notifyListeners();
  }

  set habitCategoryId(int id) {
    final previousCategoryId = _habitCategoryId;
    final hasCategoryDefaultNotifs = _matchesCategoryDefaultNotificationTimes(
      _habitNotificationTimes,
      previousCategoryId,
    );

    _habitCategoryId = id;

    if (hasCategoryDefaultNotifs) {
      _habitNotificationTimes = _buildDefaultNotificationTimesForCategory(id);
    }
    notifyListeners();
  }

  set habitAmount(int value) {
    _habitAmount = value;
    notifyListeners();
  }

  set habitDuration(Duration value) {
    _habitDuration = value;
    notifyListeners();
  }

  set habitColor(Color? color) {
    _habitColor = color;
    notifyListeners();
  }

  Color? get habitColor => _habitColor;

  set habitColorName(String? value) {
    _habitColorName = value;
    notifyListeners();
  }

  void reset() {
    _selectedHabitId = -1;
    _habitAmount = 0;
    _showAllHabits = true;

    _habitDuration = Duration.zero;
    _selectedHabitTrackingType = null;

    _habitCategoryId = 1;
    habitAmountLabelController.text = AmountLabelPreset.times.plural;
    nameController.clear();
    descController.clear();
    _iconPath = EmojiService.defaultEmoji;
    _isOptional = false;

    _timeIntervalEnabled = false;
    _timeIntervalStart = 420;
    _timeIntervalEnd = 450;
    _habitNotificationsEnabled = false;
    _habitNotificationTimes = _buildDefaultNotificationTimesForCategory(
      _habitCategoryId,
    );

    _habitColor = null;
    _habitColorName = null;
    _selectedScheduleOption = ScheduleType.daily;
    _weeklyTarget = 1;
    _monthlyTarget = 1;
    _customIntervalDays = 2;
    _selectedDaysAWeek.clear();
    _selectedDaysAMonth.clear();
    _selectedPremadeHabitType = null;

    notifyListeners();
  }

  int get selectedHabitId => _selectedHabitId;

  int get habitCategoryId => _habitCategoryId;

  int get habitAmount => _habitAmount;

  Duration get habitDuration => _habitDuration;

  String get iconPath => _iconPath;

  bool get isOptional => _isOptional;

  Color? getHabitColor(ThemeProvider tp) {
    if (_habitColorName != null) {
      final spec = OldColorService.habitColorSpecs[_habitColorName!];
      if (spec != null) {
        return tp.isDark ? spec.dark : spec.light;
      }
    }
    return null;
  }

  Color? getHabitTextColor(ThemeProvider tp) {
    if (_habitColorName != null) {
      final spec = OldColorService.habitColorSpecs[_habitColorName!];
      if (spec != null) {
        return tp.isDark ? spec.darkText : spec.lightText;
      }
    }
    if (_habitColor != null) {
      // provide minimal contrast by flipping toward darker tone for text
      return tp.isDark ? _habitColor!.lighten(35) : _habitColor!.darken(35);
    }
    return null;
  }

  String? get habitColorName => _habitColorName;

  int _getDefaultNotificationTimeForCategory(int categoryId) {
    switch (categoryId) {
      case 2:
        return 9 * 60; // Morning 09:00
      case 3:
        return 14 * 60; // Afternoon 14:00
      case 4:
        return 21 * 60; // Evening 21:00
      case 1:
      default:
        return 9 * 60; // Any time 09:00
    }
  }

  List<HabitNotificationTime> _buildDefaultNotificationTimesForCategory(
    int categoryId,
  ) {
    return [
      HabitNotificationTime(
        id: DateTime.now().microsecondsSinceEpoch,
        minutesOfDay: _getDefaultNotificationTimeForCategory(categoryId),
      ),
    ];
  }

  bool _matchesCategoryDefaultNotificationTimes(
    List<HabitNotificationTime> notificationTimes,
    int categoryId,
  ) {
    if (notificationTimes.length != 1) {
      return false;
    }

    return notificationTimes.first.minutesOfDay ==
        _getDefaultNotificationTimeForCategory(categoryId);
  }
}
