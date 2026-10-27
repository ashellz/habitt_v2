import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/util/streak_milestones.dart';

void main() {
  group('crossedMilestone', () {
    test('reaching 7 exactly crosses 7', () {
      expect(crossedMilestone(celebrated: 6, streak: 7), 7);
    });

    test('growing within a milestone crosses nothing', () {
      expect(crossedMilestone(celebrated: 3, streak: 4), isNull);
      expect(crossedMilestone(celebrated: 7, streak: 8), isNull);
    });

    test('a back-filled day can jump over 7', () {
      expect(crossedMilestone(celebrated: 5, streak: 9), 7);
    });

    test('reaching 30 crosses 30', () {
      expect(crossedMilestone(celebrated: 29, streak: 30), 30);
    });

    test('the highest milestone wins when several are crossed', () {
      expect(crossedMilestone(celebrated: 3, streak: 31), 30);
    });

    test('an already celebrated milestone is not crossed again', () {
      expect(crossedMilestone(celebrated: 7, streak: 7), isNull);
      expect(crossedMilestone(celebrated: 30, streak: 35), isNull);
    });

    test('a streak that broke and regrew crosses 7 again', () {
      // celebrated follows the streak down when it breaks
      expect(crossedMilestone(celebrated: 2, streak: 7), 7);
    });
  });
}
