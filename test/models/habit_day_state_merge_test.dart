import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/habit.dart';

/// These tests lock the cross-device sync fix (change: fix-sync-day-state-leak).
///
/// Day-state = completion tuple: completed / skipped / amountCompleted /
/// durationCompleted. The rules under test:
///   1. Master-record merge is definition-only: incoming day-state never
///      overwrites the live habit (preserveLocalDayState: true).
///   2. Within a dated Day snapshot, the completion tuple resolves as ONE unit
///      (no contradictory `completed == true && amountCompleted == 0`).
///   3. An incoming real completion heals a reset/blank local day habit.
///   4. adoptDayState rebuilds a live habit's "today" from today's snapshot.
Habit _habit({
  int id = 1,
  String name = 'Drink water',
  int amount = 5,
  int amountCompleted = 0,
  bool completed = false,
  bool skipped = false,
  int durationCompleted = 0,
  Map<String, DateTime>? timestamps,
}) {
  return Habit(
    id: id,
    name: name,
    iconPath: '',
    categoryId: 0,
    amount: amount,
    amountCompleted: amountCompleted,
    completed: completed,
    skipped: skipped,
    durationCompleted: durationCompleted,
    trackingType: HabitTrackingType.amount,
    timestamps: timestamps,
  );
}

void main() {
  final now = DateTime.utc(2026, 6, 22, 9);
  final dayNEarly = DateTime.utc(2026, 6, 21, 22); // A completed at 22:00
  final dayNLate = DateTime.utc(2026, 6, 21, 23); // B partial at 23:00

  group('master-record merge is definition-only', () {
    test('incoming completion does NOT overwrite local day-state', () {
      final local = _habit(
        name: 'Water',
        completed: false,
        amountCompleted: 0,
      );
      final incoming = _habit(
        name: 'Hydrate', // definition change, newer
        completed: true,
        amountCompleted: 5,
        timestamps: {
          'name': dayNLate,
          'completed': dayNEarly,
          'amountCompleted': dayNEarly,
        },
      );

      final merged = local.merge(
        incoming,
        reference: now,
        preserveLocalDayState: true,
      );

      // Definition field still syncs.
      expect(merged.name, 'Hydrate');
      // Day-state stays local — the dateless leak is severed.
      expect(merged.completed, isFalse);
      expect(merged.amountCompleted, 0);
    });
  });

  group('day-snapshot merge resolves the completion tuple as a unit', () {
    test('never produces completed==true with amountCompleted==0', () {
      // B made partial progress (2/5) later; A fully completed (5/5) earlier.
      final local = _habit(
        amountCompleted: 2,
        completed: false,
        timestamps: {'amountCompleted': dayNLate},
      );
      final incoming = _habit(
        amountCompleted: 5,
        completed: true,
        timestamps: {'completed': dayNEarly, 'amountCompleted': dayNEarly},
      );

      final merged = local.merge(incoming, reference: now);

      // Core guarantee: completion fields are internally consistent.
      expect(merged.completed && merged.amountCompleted == 0, isFalse);
      // Most-recent interaction (B's partial) wins the whole tuple.
      expect(merged.completed, isFalse);
      expect(merged.amountCompleted, 2);
    });

    test('incoming real completion heals a reset/blank local day habit', () {
      // Local day-N snapshot frozen from incomplete state: no day-state stamps.
      final local = _habit(completed: false, amountCompleted: 0);
      final incoming = _habit(
        completed: true,
        amountCompleted: 5,
        timestamps: {'completed': dayNEarly, 'amountCompleted': dayNEarly},
      );

      final merged = local.merge(incoming, reference: now);

      expect(merged.completed, isTrue);
      expect(merged.amountCompleted, 5);
    });
  });

  group('adoptDayState rebuilds live today from snapshot', () {
    test('copies completion fields from snapshot habit onto live habit', () {
      final live = _habit(completed: false, amountCompleted: 0);
      final snapshot = _habit(
        completed: true,
        amountCompleted: 5,
        timestamps: {'completed': dayNEarly, 'amountCompleted': dayNEarly},
      );

      live.adoptDayState(snapshot);

      expect(live.completed, isTrue);
      expect(live.amountCompleted, 5);
      expect(live.timestamps['completed'], dayNEarly);
    });
  });
}
