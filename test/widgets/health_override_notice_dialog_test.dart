import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/health_override_notice.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/dialogs/health_override_notice_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpHost(
  WidgetTester tester, {
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => ColorProvider(prefs),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () => HealthOverrideNotice.showIfNeeded(context),
                  child: const Text('open'),
                ),
              ),
        ),
      ),
    ),
  );
}

bool _understoodEnabled(WidgetTester tester) =>
    tester
        .widget<NewDefaultButton>(
          find.ancestor(
            of: find.textContaining('Understood'),
            matching: find.byType(NewDefaultButton),
          ),
        )
        .enabled;

void main() {
  testWidgets('the button counts down 3, 2, 1 before it can be pressed', (
    tester,
  ) async {
    await _pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Understood (3)'), findsOneWidget);
    expect(_understoodEnabled(tester), isFalse);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Understood (2)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Understood (1)'), findsOneWidget);
    expect(_understoodEnabled(tester), isFalse);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Understood'), findsOneWidget);
    expect(_understoodEnabled(tester), isTrue);

    // close it so the notice's in-flight guard is released for the next test
    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();
  });

  testWidgets('shows only once, then never again', (tester) async {
    await _pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(HealthOverrideNoticeDialog), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();
    expect(find.byType(HealthOverrideNoticeDialog), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(HealthOverrideNoticeDialog), findsNothing);
  });

  testWidgets('does not show if it was already shown before', (tester) async {
    await _pumpHost(
      tester,
      prefsValues: {HealthOverrideNotice.shownKey: true},
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(HealthOverrideNoticeDialog), findsNothing);
  });

  testWidgets('cannot be dismissed by tapping outside during the countdown', (
    tester,
  ) async {
    await _pumpHost(tester);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.byType(HealthOverrideNoticeDialog), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Understood'));
    await tester.pumpAndSettle();
  });
}
