import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/whats_new.dart';

void main() {
  final cutoff = DateTime(2026, 11, 10);

  bool due(DateTime joined, String? seen, {String current = '2.5.0'}) =>
      shouldShowWhatsNew(
        dateJoined: joined,
        lastSeenVersion: seen,
        currentVersion: current,
        cutoff: cutoff,
      );

  test('shown to an existing user who has not seen this version', () {
    expect(due(DateTime(2025, 3, 1), null), isTrue);
    expect(due(DateTime(2026, 11, 9, 23, 59), null), isTrue);
  });

  test('shown when the last seen version is an older one', () {
    expect(due(DateTime(2025, 3, 1), '2.4.2'), isTrue);
  });

  test('not shown again once the current version was seen', () {
    expect(due(DateTime(2025, 3, 1), '2.5.0'), isFalse);
  });

  test('never shown to users who joined on or after the cutoff', () {
    expect(due(DateTime(2026, 11, 10), null), isFalse);
    expect(due(DateTime(2026, 11, 10, 18, 30), null), isFalse);
    expect(due(DateTime(2027, 1, 5), '2.4.2'), isFalse);
  });

  test('a later release is shown again to users who saw the earlier one', () {
    expect(due(DateTime(2025, 3, 1), '2.5.0', current: '2.6.0'), isTrue);
  });

  test('defaults to the app constants', () {
    expect(
      shouldShowWhatsNew(
        dateJoined: kWhatsNewCutoff.subtract(const Duration(days: 1)),
        lastSeenVersion: null,
      ),
      isTrue,
    );
    expect(
      shouldShowWhatsNew(dateJoined: kWhatsNewCutoff, lastSeenVersion: null),
      isFalse,
    );
    expect(
      shouldShowWhatsNew(
        dateJoined: kWhatsNewCutoff.subtract(const Duration(days: 1)),
        lastSeenVersion: kWhatsNewVersion,
      ),
      isFalse,
    );
  });
}
