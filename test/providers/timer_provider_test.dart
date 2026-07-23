import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/active_timer_session.dart';
import 'package:habitt/providers/timer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActiveTimerSession', () {
    test('round-trips through JSON', () {
      final s = ActiveTimerSession(
        habitId: 42,
        dayKey: '2026-07-22',
        baselineDurationCompleted: 300,
        accumulatedSeconds: 90,
        lastResumedAt: DateTime.utc(2026, 7, 22, 10, 30),
        status: TimerStatus.running,
      );
      final back = ActiveTimerSession.fromJson(s.toJson());
      expect(back.habitId, 42);
      expect(back.dayKey, '2026-07-22');
      expect(back.baselineDurationCompleted, 300);
      expect(back.accumulatedSeconds, 90);
      expect(back.lastResumedAt, DateTime.utc(2026, 7, 22, 10, 30));
      expect(back.status, TimerStatus.running);
    });
  });

  group('TimerProvider', () {
    test('start creates a running session for the habit', () async {
      final prefs = await SharedPreferences.getInstance();
      final tp = TimerProvider(prefs);

      final ok = tp.start(
        habitId: 1,
        day: DateTime.now(),
        durationCompleted: 0,
      );

      expect(ok, isTrue);
      expect(tp.hasActiveTimer, isTrue);
      expect(tp.activeHabitId, 1);
      expect(tp.isRunning, isTrue);
      expect(tp.isActiveHabit(1), isTrue);
    });

    test('start refuses a second habit while one is active', () async {
      final prefs = await SharedPreferences.getInstance();
      final tp = TimerProvider(prefs);
      tp.start(habitId: 1, day: DateTime.now(), durationCompleted: 0);

      final ok = tp.start(
        habitId: 2,
        day: DateTime.now(),
        durationCompleted: 0,
      );

      expect(ok, isFalse);
      expect(tp.activeHabitId, 1);
    });

    test('pause then resume toggles status', () async {
      final prefs = await SharedPreferences.getInstance();
      final tp = TimerProvider(prefs);
      tp.start(habitId: 1, day: DateTime.now(), durationCompleted: 0);

      await tp.pause();
      expect(tp.isPaused, isTrue);
      expect(tp.isRunning, isFalse);

      tp.resume();
      expect(tp.isRunning, isTrue);
    });

    test('stop clears the session and its persisted copy', () async {
      final prefs = await SharedPreferences.getInstance();
      final tp = TimerProvider(prefs);
      tp.start(habitId: 1, day: DateTime.now(), durationCompleted: 0);
      expect(prefs.getString('activeTimerSession_v1'), isNotNull);

      await tp.stop();

      expect(tp.hasActiveTimer, isFalse);
      expect(prefs.getString('activeTimerSession_v1'), isNull);
    });

    test('liveProgressSeconds = baseline + elapsed (>= baseline)', () async {
      final prefs = await SharedPreferences.getInstance();
      final tp = TimerProvider(prefs);
      tp.start(habitId: 1, day: DateTime.now(), durationCompleted: 600);

      expect(tp.liveProgressSeconds, greaterThanOrEqualTo(600));
      expect(tp.liveProgressFor(1), greaterThanOrEqualTo(600));
      expect(tp.liveProgressFor(2), isNull);
    });

    test('restores a persisted paused session on construction', () async {
      final seed = ActiveTimerSession(
        habitId: 7,
        dayKey: '2026-07-22',
        baselineDurationCompleted: 120,
        accumulatedSeconds: 45,
        lastResumedAt: null,
        status: TimerStatus.paused,
      );
      SharedPreferences.setMockInitialValues({
        'activeTimerSession_v1': seed.toJson(),
      });
      final prefs = await SharedPreferences.getInstance();

      final tp = TimerProvider(prefs);

      expect(tp.hasActiveTimer, isTrue);
      expect(tp.activeHabitId, 7);
      expect(tp.isPaused, isTrue);
      expect(tp.sessionElapsedSeconds, 45);
      expect(tp.liveProgressSeconds, 165);
    });

    test('clearIfActive only clears when the id matches', () async {
      final prefs = await SharedPreferences.getInstance();
      final tp = TimerProvider(prefs);
      tp.start(habitId: 1, day: DateTime.now(), durationCompleted: 0);

      tp.clearTimerIfActive(2);
      expect(tp.hasActiveTimer, isTrue);

      tp.clearTimerIfActive(1);
      expect(tp.hasActiveTimer, isFalse);
    });
  });
}
