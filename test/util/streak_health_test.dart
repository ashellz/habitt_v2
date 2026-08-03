import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/models/streak_health.dart';

void main() {
  group('resolveStreakHealth', () {
    StreakHealth resolve(
      int tailMisses, {
      bool secure = false,
      int streak = 18,
    }) {
      return resolveStreakHealth(
        streak: streak,
        tailMisses: tailMisses,
        todayIsSecure: secure,
      );
    }

    test('full slack is healthy regardless of today', () {
      expect(resolve(0), StreakHealth.healthy);
      expect(resolve(0, secure: true), StreakHealth.healthy);
    });

    test('one miss and today not yet secured → fading', () {
      expect(resolve(1), StreakHealth.fading);
    });

    test('two misses and today not yet secured → critical', () {
      expect(resolve(2), StreakHealth.critical);
    });

    test('securing today clears the warning at any tolerance', () {
      expect(resolve(1, secure: true), StreakHealth.healthy);
      expect(resolve(2, secure: true), StreakHealth.healthy);
    });

    test('no streak to protect → dormant, whatever the tolerance', () {
      expect(resolve(0, streak: 0), StreakHealth.dormant);
      expect(resolve(2, streak: 0), StreakHealth.dormant);
      // A fresh user who has missed three days has spent tolerance but has no
      // streak — "last chance to save your 0-day streak" would be nonsense.
      expect(resolve(3, streak: 0), StreakHealth.dormant);
    });

    test('dormant wins over a secured today', () {
      // The first perfect day does not surface a streak of 1 mid-day; it
      // becomes visible when the day rolls over.
      expect(resolve(0, streak: 0, secure: true), StreakHealth.dormant);
    });

    test('tolerance beyond two stays critical while a streak survives', () {
      expect(resolve(3), StreakHealth.critical);
    });
  });
}
