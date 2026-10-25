import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/stats_range.dart';

void main() {
  final today = DateTime(2026, 3, 10, 15, 30);

  test('7D starts six days back so today is the seventh day', () {
    expect(StatsRange.week.startFor(today), DateTime(2026, 3, 4));
  });

  test('30D crosses month boundaries', () {
    expect(StatsRange.month.startFor(today), DateTime(2026, 2, 9));
  });

  test('ALL has no start', () {
    expect(StatsRange.all.startFor(today), isNull);
  });
}
