import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/services/widget_launch_handler.dart';

void main() {
  group('parse', () {
    test('home', () {
      expect(
        WidgetLaunchHandler.parse(Uri.parse('habitt://widget/home')),
        isA<WidgetLaunchHome>(),
      );
    });

    test('log with a habit, including the iOS homeWidget marker', () {
      final launch = WidgetLaunchHandler.parse(
        Uri.parse('habitt://widget/log?habit=42&homeWidget'),
      );
      expect(launch, isA<WidgetLaunchLog>());
      expect((launch as WidgetLaunchLog).habitId, 42);
    });

    test('log without a valid habit falls back to home', () {
      expect(
        WidgetLaunchHandler.parse(Uri.parse('habitt://widget/log?habit=x')),
        isA<WidgetLaunchHome>(),
      );
    });

    test('anything else is ignored', () {
      expect(WidgetLaunchHandler.parse(null), isNull);
      expect(
        WidgetLaunchHandler.parse(Uri.parse('https://widget/home')),
        isNull,
      );
      expect(
        WidgetLaunchHandler.parse(Uri.parse('habitt://other/home')),
        isNull,
      );
      expect(WidgetLaunchHandler.parse(Uri.parse('habitt://widget/x')), isNull);
    });
  });

  group('handle', () {
    test('a log tap opens that habit for today', () {
      int? opened;
      DateTime? openedDay;
      var home = 0;
      WidgetLaunchHandler.handle(
        Uri.parse('habitt://widget/log?habit=7'),
        openHabit: (id, day) {
          opened = id;
          openedDay = day;
        },
        openHome: () => home++,
        now: () => DateTime(2026, 11, 24, 21, 15),
      );
      expect(opened, 7);
      expect(openedDay, DateTime(2026, 11, 24));
      expect(home, 0);
    });

    test('a home tap opens the home page', () {
      var home = 0;
      WidgetLaunchHandler.handle(
        Uri.parse('habitt://widget/home'),
        openHabit: (_, __) => fail('should not open a habit'),
        openHome: () => home++,
      );
      expect(home, 1);
    });

    test('a foreign URI does nothing', () {
      WidgetLaunchHandler.handle(
        Uri.parse('https://example.com'),
        openHabit: (_, __) => fail('should not open a habit'),
        openHome: () => fail('should not open home'),
      );
    });
  });
}
