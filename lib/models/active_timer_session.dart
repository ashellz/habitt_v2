import 'dart:convert';

enum TimerStatus { running, paused }

// local single timer session, not synced or backed up, only one session active at a time
class ActiveTimerSession {
  ActiveTimerSession({
    required this.habitId,
    required this.dayKey,
    required this.baselineDurationCompleted,
    this.accumulatedSeconds = 0,
    this.lastResumedAt,
    this.status = TimerStatus.running,
  });

  final int habitId;

  // `yyyy-MM-dd` for the day the timer started, if midnight crossed still assinged to the started day
  final String dayKey;

  /// total progress = [baselineDurationCompleted] + session elapsed
  // Reset when the habit is completed (→ target) or progress is edited
  // manually while paused, so resumed time continues from the new value.
  int baselineDurationCompleted;

  /// Seconds banked before the last resume (i.e. already accounted for and not
  /// covered by the [lastResumedAt] running window).
  int accumulatedSeconds;

  /// UTC wall-clock time the timer last entered the running state. Null while
  /// paused.
  DateTime? lastResumedAt;

  TimerStatus status;

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;

  Map<String, dynamic> toMap() => {
    'habitId': habitId,
    'dayKey': dayKey,
    'baselineDurationCompleted': baselineDurationCompleted,
    'accumulatedSeconds': accumulatedSeconds,
    'lastResumedAt': lastResumedAt?.toIso8601String(),
    'status': status.name,
  };

  factory ActiveTimerSession.fromMap(Map<String, dynamic> m) {
    return ActiveTimerSession(
      habitId: m['habitId'] as int,
      dayKey: m['dayKey'] as String,
      baselineDurationCompleted: (m['baselineDurationCompleted'] as int?) ?? 0,
      accumulatedSeconds: (m['accumulatedSeconds'] as int?) ?? 0,
      lastResumedAt:
          (m['lastResumedAt'] as String?) != null
              ? DateTime.tryParse(m['lastResumedAt'] as String)?.toUtc()
              : null,
      status: TimerStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => TimerStatus.paused,
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ActiveTimerSession.fromJson(String source) =>
      ActiveTimerSession.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
