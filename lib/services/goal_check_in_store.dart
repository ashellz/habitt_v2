import 'package:habitt/services/goal_check_in_analyzer.dart';
import 'package:habitt/util/date_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local state for the goal check-in, in SharedPreferences: when the weekly
/// sheet was last shown, per habit and direction cooldowns, and which habits
/// already got the lighter-day sheet today. Device-local, never synced. See
/// docs/goal_check_in.md.
class GoalCheckInStore {
  GoalCheckInStore(this._prefs, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;

  static const String lastShownKey = 'goal_check_in_last_shown';
  static const String _cooldownPrefix = 'goal_check_in_cooldown';
  static const String _lighterShownPrefix = 'lighter_day_shown';

  static const Duration cadence = Duration(days: 7);
  static const Duration cooldown = Duration(days: 14);

  static Future<GoalCheckInStore> load() async =>
      GoalCheckInStore(await SharedPreferences.getInstance());

  static String cooldownKey(int habitId, GoalDirection direction) =>
      '${_cooldownPrefix}_${habitId}_${direction.name}';

  DateTime? get lastShown =>
      DateTime.tryParse(_prefs.getString(lastShownKey) ?? '');

  /// The weekly sheet may show: never shown, or shown [cadence] ago or more.
  bool get weeklyDue {
    final last = lastShown;
    return last == null || !_clock().isBefore(last.add(cadence));
  }

  Future<void> markShown() =>
      _prefs.setString(lastShownKey, _clock().toIso8601String());

  /// Directions in cooldown for [habitId].
  Set<GoalDirection> blocked(int habitId) {
    final now = _clock();
    return {
      for (final d in GoalDirection.values)
        if (DateTime.tryParse(_prefs.getString(cooldownKey(habitId, d)) ?? '')
                ?.isAfter(now) ??
            false)
          d,
    };
  }

  Future<void> startCooldown(int habitId, Iterable<GoalDirection> directions) =>
      Future.wait([
        for (final d in directions)
          _prefs.setString(
            cooldownKey(habitId, d),
            _clock().add(cooldown).toIso8601String(),
          ),
      ]);

  Future<void> clearCooldown(
    int habitId,
    Iterable<GoalDirection> directions,
  ) => Future.wait([
    for (final d in directions) _prefs.remove(cooldownKey(habitId, d)),
  ]);

  String _lighterKey(int habitId) =>
      '${_lighterShownPrefix}_${habitId}_${dateKey(_clock())}';

  bool lighterShownToday(int habitId) =>
      _prefs.getBool(_lighterKey(habitId)) ?? false;

  Future<void> markLighterShown(int habitId) =>
      _prefs.setBool(_lighterKey(habitId), true);
}
