import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/widgets/support/support_banner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SupportProvider _support;

// A user who has used the app for 10 days with 12 completions.
Future<void> _pumpBanner(
  WidgetTester tester, {
  bool supporter = false,
}) async {
  final firstSeen = DateTime.now().subtract(const Duration(days: 10));
  SharedPreferences.setMockInitialValues({
    'support_first_seen_ms': firstSeen.millisecondsSinceEpoch,
    kTotalCompletionsKey: 12,
  });
  final prefs = await SharedPreferences.getInstance();
  _support = SupportProvider(
    prefs,
    readSupporter: () => supporter,
    checkSupporter: () async => supporter,
    platformSupportsAsks: true,
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ColorProvider(prefs)),
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
        home: const Scaffold(body: SupportBanner()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the message and both actions when eligible', (
    tester,
  ) async {
    await _pumpBanner(tester);

    expect(find.textContaining('no ads, no tracking'), findsOneWidget);
    expect(find.text('See ways to support'), findsOneWidget);
    expect(find.text('I already donated'), findsOneWidget);
  });

  testWidgets('shows nothing to a subscriber', (tester) async {
    await _pumpBanner(tester, supporter: true);

    expect(find.text('See ways to support'), findsNothing);
  });

  testWidgets('the X dismisses it', (tester) async {
    await _pumpBanner(tester);

    await tester.tap(find.bySemanticsLabel('Dismiss'));
    await tester.pumpAndSettle();

    expect(find.text('See ways to support'), findsNothing);
    expect(_support.bannerVisible, isFalse);
    expect(_support.donated, isFalse);
  });

  testWidgets('"I already donated" hides it for good', (tester) async {
    await _pumpBanner(tester);

    await tester.tap(find.text('I already donated'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('See ways to support'), findsNothing);
    expect(_support.donated, isTrue);

    // let the toast leave so no timer is left pending
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('"I already donated" says thank you in a toast', (tester) async {
    await _pumpBanner(tester);

    await tester.tap(find.text('I already donated'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Thank you for supporting Habitt'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Thank you for supporting Habitt'), findsNothing);
  });
}
