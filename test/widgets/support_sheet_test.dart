import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/preferences_provider.dart';
import 'package:habitt/providers/state_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/services/theme_catalog.dart';
import 'package:habitt/util/support_sheet_flow.dart';
import 'package:habitt/util/support_thanks.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/settings/theme_picker.dart';
import 'package:habitt/widgets/support/support_row.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SupportProvider _support;
late StateProvider _state;
late ColorProvider _cp;
late DateTime _now;
var _soundPlays = 0;

Future<void> _pump(
  WidgetTester tester, {
  required Widget body,
  bool donated = false,
  bool completionSound = true,
}) async {
  _now = DateTime(2026, 11, 3, 9);
  _soundPlays = 0;
  donationSound = () async => _soundPlays++;
  SharedPreferences.setMockInitialValues({
    'color_mode': ColorMode.light.toString(),
    'play_completion_sound': completionSound,
    if (donated) 'support_donated': true,
  });
  final prefs = await SharedPreferences.getInstance();
  _cp = ColorProvider(prefs);
  _state = StateProvider(prefs);
  _support = SupportProvider(
    prefs,
    readSupporter: () => false,
    checkSupporter: () async => false,
    platformSupportsAsks: true,
    clock: () => _now,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ColorProvider>.value(value: _cp),
        ChangeNotifierProvider(create: (_) => PreferencesProvider(prefs)),
        ChangeNotifierProvider<StateProvider>.value(value: _state),
        ChangeNotifierProvider<SupportProvider>.value(value: _support),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: body)),
      ),
    ),
  );
  await tester.pump();
}

Widget _opener() => Builder(
  builder:
      (context) => TextButton(
        onPressed: () => maybeShowSupportSheet(context),
        child: const Text('open'),
      ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _letToastLeave(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  group('sheet', () {
    testWidgets('says it is free and offers three ways out', (tester) async {
      await _pump(tester, body: _opener());
      await _open(tester);

      expect(find.text('Free for everyone'), findsOneWidget);
      expect(find.textContaining('free for everyone'), findsOneWidget);
      expect(find.text('See ways to support'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.text('I already donated'), findsOneWidget);
    });

    testWidgets('never calls anything premium or claims running costs', (
      tester,
    ) async {
      await _pump(tester, body: _opener());
      await _open(tester);

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '');
      final all = texts.join(' ').toLowerCase();
      expect(all.contains('premium'), isFalse);
      expect(all.contains('cost'), isFalse);
      expect(all.contains('server'), isFalse);
    });

    testWidgets('stacks the actions: see ways, then not now, then donated', (
      tester,
    ) async {
      await _pump(tester, body: _opener());
      await _open(tester);

      final seeWays = tester.getRect(find.text('See ways to support'));
      final notNow = tester.getRect(find.text('Not now'));
      final donated = tester.getRect(find.text('I already donated'));

      expect(seeWays.center.dy, lessThan(notNow.center.dy));
      expect(notNow.center.dy, lessThan(donated.center.dy));
      // one column: the two buttons are the same width, centred on each other
      final primary = tester.getRect(
        find.ancestor(
          of: find.text('See ways to support'),
          matching: find.byType(NewDefaultButton),
        ),
      );
      final secondary = tester.getRect(
        find.ancestor(
          of: find.text('Not now'),
          matching: find.byType(NewDefaultButton),
        ),
      );
      expect(primary.width, secondary.width);
      expect(primary.left, secondary.left);
      expect(primary.bottom, lessThan(secondary.top));
    });

    testWidgets('"Not now" closes it', (tester) async {
      await _pump(tester, body: _opener());
      await _open(tester);

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('Free for everyone'), findsNothing);
      expect(_support.donated, isFalse);
    });

    testWidgets('"I already donated" closes it, thanks and remembers', (
      tester,
    ) async {
      await _pump(tester, body: _opener());
      await _open(tester);

      await tester.tap(find.text('I already donated'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Free for everyone'), findsNothing);
      expect(find.text('Thank you for supporting Habitt'), findsOneWidget);
      expect(_support.donated, isTrue);
      await _letToastLeave(tester);
    });

    testWidgets('"I already donated" plays the completion sound', (
      tester,
    ) async {
      await _pump(tester, body: _opener());
      await _open(tester);

      await tester.tap(find.text('I already donated'));
      await tester.pump();

      expect(_soundPlays, 1);
      await _letToastLeave(tester);
    });

    testWidgets('stays silent when completion sounds are off', (tester) async {
      await _pump(tester, body: _opener(), completionSound: false);
      await _open(tester);

      await tester.tap(find.text('I already donated'));
      await tester.pump();

      expect(_soundPlays, 0);
      expect(_support.donated, isTrue);
      await _letToastLeave(tester);
    });
  });

  group('maybeShowSupportSheet', () {
    testWidgets(
      'shows once, however it was dismissed, then again after 30 days',
      (tester) async {
        await _pump(tester, body: _opener());

        await _open(tester);
        expect(find.text('Free for everyone'), findsOneWidget);

        // dismissed by tapping away, not by a button
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.text('Free for everyone'), findsNothing);

        await _open(tester);
        expect(find.text('Free for everyone'), findsNothing);

        _now = DateTime(2026, 12, 2, 9); // 29 days later
        await _open(tester);
        expect(find.text('Free for everyone'), findsNothing);

        _now = DateTime(2026, 12, 3, 9); // 30 days later
        await _open(tester);
        expect(find.text('Free for everyone'), findsOneWidget);
      },
    );

    testWidgets('is not shown to a donor', (tester) async {
      await _pump(tester, body: _opener(), donated: true);
      await _open(tester);

      expect(find.text('Free for everyone'), findsNothing);
    });

    testWidgets('waits while the streak celebration is up, and stays due', (
      tester,
    ) async {
      await _pump(tester, body: _opener());
      _state.streakCelebrationPendingOrActive = true;
      await _open(tester);

      expect(find.text('Free for everyone'), findsNothing);
      expect(_support.sheetDue, isTrue);
    });

    testWidgets('does not use the ask budget', (tester) async {
      await _pump(tester, body: _opener());
      await _open(tester);

      expect(_support.claimedToday, isFalse);
    });
  });

  group('support row', () {
    testWidgets('is shown to a regular user', (tester) async {
      await _pump(tester, body: const SupportRow());
      expect(find.text('Support Habitt'), findsOneWidget);
    });

    testWidgets('is hidden for a donor', (tester) async {
      await _pump(tester, body: const SupportRow(), donated: true);
      expect(find.text('Support Habitt'), findsNothing);
    });
  });

  group('theme picker', () {
    testWidgets('the first new theme shows the sheet after it is applied', (
      tester,
    ) async {
      await _pump(tester, body: const ThemePicker());
      expect(find.text('Support Habitt'), findsOneWidget);

      await tester.tap(find.text('Ocean'));
      await tester.pump();
      expect(_cp.theme, ThemeCatalog.ocean);
      expect(find.text('Free for everyone'), findsNothing);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Free for everyone'), findsOneWidget);
    });

    testWidgets('later picks, and tapping the current theme, show nothing', (
      tester,
    ) async {
      await _pump(tester, body: const ThemePicker());

      await tester.tap(find.text('Habitt'));
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Free for everyone'), findsNothing);
      expect(_support.sheetDue, isTrue);

      await tester.tap(find.text('Ocean'));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Violet'));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Free for everyone'), findsNothing);
      expect(_cp.theme, ThemeCatalog.violet);
    });

    testWidgets('the row is gone for a donor', (tester) async {
      await _pump(tester, body: const ThemePicker(), donated: true);
      expect(find.text('Support Habitt'), findsNothing);
      expect(find.text('Ocean'), findsOneWidget);
    });
  });
}
