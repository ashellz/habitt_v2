import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/util/health_history.dart';
import 'package:habitt/widgets/habit_details/health_stats/health_week_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

HealthHistory _history(
  HealthHistoryKind kind,
  List<double?> values, {
  double target = 100,
  double tolerance = 0,
}) {
  return HealthHistory(
    kind: kind,
    target: target,
    tolerance: tolerance,
    points: [
      for (var i = 0; i < values.length; i++)
        HealthDayPoint(
          day: DateTime(2026, 10, 15 + i),
          value: values[i],
          completed: (values[i] ?? 0) >= target,
        ),
    ],
  );
}

Future<void> _pump(WidgetTester tester, HealthHistory history) async {
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
            child: HealthWeekChart(history: history),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders bars for a count habit with missing days', (
    tester,
  ) async {
    await _pump(
      tester,
      _history(HealthHistoryKind.amount, [
        8000,
        null,
        12000,
        3000,
        null,
        9000,
        500,
      ], target: 8000),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(HealthWeekChart), findsOneWidget);
  });

  testWidgets('renders bars when there is no target', (tester) async {
    await _pump(
      tester,
      _history(HealthHistoryKind.duration, [
        0,
        600,
        null,
        null,
        1200,
        0,
        300,
      ], target: 0),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders sleep minutes', (tester) async {
    await _pump(
      tester,
      _history(HealthHistoryKind.sleepMinutes, [
        420,
        450,
        null,
        510,
        380,
        480,
        495,
      ], target: 480),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders bedtimes past midnight with a tolerance band', (
    tester,
  ) async {
    await _pump(
      tester,
      _history(HealthHistoryKind.timeOfDay, [
        1380,
        1410,
        null,
        1500,
        1395,
        null,
        1440 + 20,
      ], target: 1380, tolerance: 30),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders wake times without a tolerance', (tester) async {
    await _pump(
      tester,
      _history(HealthHistoryKind.timeOfDay, [
        410,
        null,
        null,
        null,
        null,
        null,
        425,
      ], target: 420),
    );

    expect(tester.takeException(), isNull);
  });
}
