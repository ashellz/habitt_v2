import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/habit_details/strength_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester,
  List<DateTime> dates,
  List<double> values, {
  DateTime? from,
  DateTime? to,
}) async {
  SharedPreferences.setMockInitialValues({});
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
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StrengthChart(
              dates: dates,
              values: values,
              from: from ?? dates.first,
              to: to ?? dates.last,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('plots strength as a percentage on a day-based axis', (
    tester,
  ) async {
    // a gap between the 3rd and 10th makes the x spacing uneven on purpose
    final dates = [
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 2),
      DateTime(2026, 10, 3),
      DateTime(2026, 10, 10),
    ];
    await _pump(tester, dates, [0.1, 0.19, 0.27, 0.5]);

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final spots = chart.data.lineBarsData.single.spots;
    expect(spots.map((s) => s.x), [0, 1, 2, 9]);
    expect(spots.last.y, closeTo(50, 1e-9));
    expect(chart.data.maxX, 9);
  });

  testWidgets('renders a habit spanning more than a year', (tester) async {
    final dates = [
      for (var i = 0; i < 500; i++) DateTime(2025, 1, 1).add(Duration(days: i)),
    ];
    await _pump(tester, dates, [for (var i = 0; i < 500; i++) i / 500]);

    expect(find.byType(LineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fixed window leaves room before the first point', (
    tester,
  ) async {
    await _pump(
      tester,
      [DateTime(2026, 10, 9)],
      [0.4],
      from: DateTime(2026, 10, 4),
      to: DateTime(2026, 10, 10),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.maxX, 6);
    expect(chart.data.lineBarsData.single.spots.single.x, 5);
  });
}
