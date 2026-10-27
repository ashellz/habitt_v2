import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/widgets/support/milestone_support_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SupportProvider _support;
var _donatedTaps = 0;

Future<void> _pumpCard(WidgetTester tester, {bool supporter = false}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  _donatedTaps = 0;
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
        home: Scaffold(
          body: MilestoneSupportCard(
            onDonated: () {
              _donatedTaps++;
              _support.markDonated();
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the message and both actions', (tester) async {
    await _pumpCard(tester);

    expect(find.textContaining('no ads and no tracking'), findsOneWidget);
    expect(find.text('See ways to support'), findsOneWidget);
    expect(find.text('I already donated'), findsOneWidget);
  });

  testWidgets('shows nothing to a subscriber', (tester) async {
    await _pumpCard(tester, supporter: true);

    expect(find.text('See ways to support'), findsNothing);
  });

  testWidgets('"I already donated" reports it and the card collapses', (
    tester,
  ) async {
    await _pumpCard(tester);

    await tester.tap(find.text('I already donated'));
    await tester.pumpAndSettle();

    expect(_donatedTaps, 1);
    expect(find.text('See ways to support'), findsNothing);
  });
}
