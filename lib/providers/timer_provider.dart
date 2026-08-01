import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:habitt/models/active_timer_session.dart';
import 'package:habitt/providers/habit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimerProvider extends ChangeNotifier {
  TimerProvider(this._prefs) {
    _restore();
  }

  final SharedPreferences _prefs;
  HabitProvider? _habitProvider;

  static const String _prefsKey = 'activeTimerSession_v1';

  // 24h cap if app was killed during a timer and resumed it will stop at 24h for that session
  static const int sanityCeilingSeconds = 24 * 3600;

  ActiveTimerSession? _session;
  Timer? _ticker;

  // true once the running session has been committed at/over the habit's
  // target, so the auto-complete commit fires once per crossing instead of
  // every tick
  bool _autoCompleted = false;
  bool _autoCompleteInFlight = false;

  // prompt the user to keep or discard the session TODO
  bool _pendingRecoveryPrompt = false;

  void attachHabitProvider(HabitProvider habitProvider) {
    _habitProvider = habitProvider;
  }

  ActiveTimerSession? get session => _session;
  bool get hasActiveTimer => _session != null;
  int? get activeHabitId => _session?.habitId;
  bool get isRunning => _session?.isRunning ?? false;
  bool get isPaused => _session?.isPaused ?? false;

  bool isActiveHabit(int habitId) => _session?.habitId == habitId;

  int get sessionElapsedSeconds {
    final s = _session;
    if (s == null) return 0;
    var elapsed = s.accumulatedSeconds;
    if (s.isRunning && s.lastResumedAt != null) {
      elapsed += _guardedDelta(s);
    }
    return elapsed;
  }

  /// total progress for [NewHabitProgress] widget
  // current duration completed + timer elapsed
  int get liveProgressSeconds {
    final s = _session;
    if (s == null) return 0;
    return s.baselineDurationCompleted + sessionElapsedSeconds;
  }

  int? liveProgressFor(int habitId) =>
      isActiveHabit(habitId) ? liveProgressSeconds : null;

  bool get hasPendingRecoveryPrompt => _pendingRecoveryPrompt;

  // used for calculating elapsed time
  // uses time elapsed, lastResumedAt, duration completed and guards it all with the 24h cap
  // guards against clock manipulation too
  int _guardedDelta(ActiveTimerSession s) {
    final resumedAt = s.lastResumedAt;
    if (resumedAt == null) return 0;
    final raw = DateTime.now().toUtc().difference(resumedAt).inSeconds;
    if (raw < 0) return 0; // clock moved back, add nothing
    final headroom =
        sanityCeilingSeconds -
        s.baselineDurationCompleted -
        s.accumulatedSeconds;
    // ceiling already reached, add nothing
    if (headroom <= 0) return 0;
    return raw > headroom ? headroom : raw;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
      unawaited(_maybeAutoComplete());
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  bool start({
    required int habitId,
    required DateTime day,
    required int durationCompleted,
  }) {
    if (_session != null && _session!.habitId != habitId) return false;
    if (_session != null && _session!.habitId == habitId) {
      resume();
      return true;
    }

    _session = ActiveTimerSession(
      habitId: habitId,
      dayKey: _dayKey(day),
      baselineDurationCompleted: durationCompleted,
      accumulatedSeconds: 0,
      lastResumedAt: DateTime.now().toUtc(),
      status: TimerStatus.running,
    );
    _autoCompleted = false;
    _persist();
    _startTicker();
    notifyListeners();
    return true;
  }

  Future<void> _maybeAutoComplete() async {
    final s = _session;
    final habitProvider = _habitProvider;
    if (s == null || habitProvider == null) return;
    if (!s.isRunning || _autoCompleteInFlight) return;

    final target = habitProvider.timerTargetDuration(
      s.habitId,
      day: DateTime.parse(s.dayKey),
    );
    if (target == null || target <= 0) {
      // habit was deleted, paused, or target removed while timer was running, so stop the timer
      forceStop();
      return;
    }

    final progress = s.baselineDurationCompleted + sessionElapsedSeconds;

    if (progress >= target) {
      if (_autoCompleted) return;
      _autoCompleted = true;
    } else {
      // target was raised past the progress we already committed, so commit
      // again to let the habit fall back to uncompleted
      if (!_autoCompleted) return;
      _autoCompleted = false;
    }

    _autoCompleteInFlight = true;
    try {
      await _commit(s.habitId, s.dayKey, progress);
    } finally {
      _autoCompleteInFlight = false;
    }
    notifyListeners();
  }

  Future<void> syncOnResume() => _maybeAutoComplete();

  Future<void> pause() async {
    final s = _session;
    if (s == null || s.isPaused) return;
    s.status = TimerStatus.paused;
    _stopTicker();
    notifyListeners();

    s.accumulatedSeconds += _guardedDelta(s);
    s.lastResumedAt = null;

    _persist();
    await _commit(
      s.habitId,
      s.dayKey,
      s.baselineDurationCompleted + s.accumulatedSeconds,
    );
    notifyListeners();
  }

  void resume() {
    final s = _session;
    if (s == null || s.isRunning) return;
    s.lastResumedAt = DateTime.now().toUtc();
    s.status = TimerStatus.running;
    _persist();
    _startTicker();
    notifyListeners();
  }

  void forceStop() {
    _stopTicker();
    _session = null;
    _autoCompleted = false;
    _prefs.remove(_prefsKey);
    notifyListeners();
  }

  Future<void> stop() async {
    final s = _session;
    if (s == null) return;
    if (s.isRunning && s.lastResumedAt != null) {
      s.accumulatedSeconds += _guardedDelta(s);
      s.lastResumedAt = null;
    }
    final habitId = s.habitId;
    final dayKey = s.dayKey;
    final durationCompleted =
        s.baselineDurationCompleted + s.accumulatedSeconds;

    _stopTicker();
    _session = null;
    _autoCompleted = false;
    notifyListeners();

    await _commit(habitId, dayKey, durationCompleted);
    _prefs.remove(_prefsKey);
  }

  // complete habit while timer is running
  Future<void> completeToTarget(int targetDuration) async {
    final s = _session;
    if (s == null) return;
    s.baselineDurationCompleted = targetDuration;
    s.accumulatedSeconds = 0;
    s.lastResumedAt = null;
    s.status = TimerStatus.paused;
    _autoCompleted = true;
    _stopTicker();
    _persist();
    await _commit(s.habitId, s.dayKey, targetDuration);
    notifyListeners();
  }

  /// rebaseline after a manual progress log while timer is paused
  /// so resume continues from the edited [durationCompleted]
  void rebaseline(int durationCompleted) {
    final s = _session;
    if (s == null) return;
    s.baselineDurationCompleted = durationCompleted;
    s.accumulatedSeconds = 0;
    // the manual log decides completion on its own, let the next tick re-decide
    _autoCompleted = false;
    _persist();
    notifyListeners();
  }

  // clear the session without committing
  void clearSession() => _clear();

  void clearTimerIfActive(int habitId) {
    if (isActiveHabit(habitId)) _clear();
  }

  void takePendingRecoveryPrompt() {
    _pendingRecoveryPrompt = false;
  }

  // saves timer to durationCompleted of the habit
  Future<void> _commit(
    int habitId,
    String dayKey,
    int durationCompleted,
  ) async {
    if (_habitProvider == null) return;
    await _habitProvider!.commitTimerDuration(
      habitId,
      durationCompleted,
      day: DateTime.parse(dayKey),
    );
  }

  void _clear() {
    _stopTicker();
    _session = null;
    _autoCompleted = false;
    _prefs.remove(_prefsKey);
    notifyListeners();
  }

  void _persist() {
    final s = _session;
    if (s == null) return;
    _prefs.setString(_prefsKey, s.toJson());
  }

  void _restore() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final s = ActiveTimerSession.fromJson(raw);
      _session = s;
      if (s.isRunning && s.lastResumedAt != null) {
        _pendingRecoveryPrompt = true;
        _startTicker();
      }
    } catch (e) {
      debugPrint('TimerProvider restore failed: $e');
      _prefs.remove(_prefsKey);
    }
  }

  String _dayKey(DateTime day) =>
      DateTime(day.year, day.month, day.day).toIso8601String().split('T').first;

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
