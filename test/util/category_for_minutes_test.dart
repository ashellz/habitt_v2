import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/category_for_minutes.dart';

int _m(int hour, [int minute = 0]) => hour * 60 + minute;

void main() {
  test('morning runs from 04:00 until 12:00', () {
    expect(categoryIdForMinutes(_m(4)), 2);
    expect(categoryIdForMinutes(_m(7, 30)), 2);
    expect(categoryIdForMinutes(_m(11, 59)), 2);
  });

  test('afternoon runs from 12:00 until 19:00', () {
    expect(categoryIdForMinutes(_m(12)), 3);
    expect(categoryIdForMinutes(_m(18, 59)), 3);
  });

  test('evening runs from 19:00 until 04:00', () {
    expect(categoryIdForMinutes(_m(19)), 4);
    expect(categoryIdForMinutes(_m(23, 59)), 4);
    expect(categoryIdForMinutes(0), 4);
    expect(categoryIdForMinutes(_m(3, 59)), 4);
  });

  test('wraps values past midnight', () {
    expect(categoryIdForMinutes(_m(24 + 8)), 2);
  });
}
