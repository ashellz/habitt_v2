import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/health_history.dart';
import 'package:habitt/util/health_missing_data.dart';

HealthHistory history(List<double?> values) {
  final start = DateTime(2026, 11, 1);
  return HealthHistory(
    kind: HealthHistoryKind.amount,
    target: 6000,
    points: [
      for (var i = 0; i < values.length; i++)
        HealthDayPoint(
          day: DateTime(start.year, start.month, start.day + i),
          value: values[i],
          completed: false,
        ),
    ],
  );
}

void main() {
  final today = DateTime(2026, 11, 7);
  final old = DateTime(2026, 10, 1);

  bool hint(List<double?> v, {DateTime? created}) => shouldHintHealthAccess(
    history: history(v),
    createdAt: created ?? old,
    today: today,
  );

  test('hints after three empty days (null or 0)', () {
    expect(hint([500, 800, null, 0, null, 0, 0]), isTrue);
  });

  test('no hint when any of the last three days has data', () {
    expect(hint([0, 0, 0, 0, 0, 0, 1200]), isFalse);
    expect(hint([0, 0, 0, 0, 900, 0, 0]), isFalse);
  });

  test('older empty days do not matter', () {
    expect(hint([null, null, null, null, 700, 800, 900]), isFalse);
  });

  test('a habit younger than three days is never flagged', () {
    expect(
      hint([null, null, null, null, 0, 0, 0], created: DateTime(2026, 11, 6)),
      isFalse,
    );
  });
}
