import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/past_day_hint.dart';

void main() {
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));

  test('eligible when not yet discovered and yesterday is trackable', () {
    expect(
      isPastDayHintEligible(
        dateJoined: today.subtract(const Duration(days: 60)),
        hasSelectedPastDay: false,
      ),
      isTrue,
    );
  });

  test('not eligible once the hint has been discovered', () {
    expect(
      isPastDayHintEligible(
        dateJoined: today.subtract(const Duration(days: 60)),
        hasSelectedPastDay: true,
      ),
      isFalse,
    );
  });

  test('not eligible when dateJoined is today (no valid yesterday)', () {
    expect(
      isPastDayHintEligible(dateJoined: today, hasSelectedPastDay: false),
      isFalse,
    );
  });

  test('eligible when dateJoined is exactly yesterday', () {
    expect(
      isPastDayHintEligible(dateJoined: yesterday, hasSelectedPastDay: false),
      isTrue,
    );
  });
}
