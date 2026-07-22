import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/get_duration_string.dart';

void main() {
  test('formats seconds as compact h/m/s, omitting zero components', () {
    expect(getDurationString(0), '0m');
    expect(getDurationString(30), '30s');
    expect(getDurationString(90), '1m30s');
    expect(getDurationString(1800), '30m');
    expect(getDurationString(3600), '1h');
    expect(getDurationString(5430), '1h30m30s');
    expect(getDurationString(3660), '1h1m');
  });
}
