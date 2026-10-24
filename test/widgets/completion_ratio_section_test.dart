import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/habit_stats_provider.dart';
import 'package:habitt/util/habit_strength_calculator.dart';
import 'package:habitt/util/stats_range.dart';
import 'package:habitt/widgets/habit_details/new/completion_ratio_section.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

HabitWeekdayRate _day(String label, int completed, int scheduled) =>
    HabitWeekdayRate(
      weekday: 1,
      label: label,
      completed: completed,
      scheduled: scheduled,
    );

HabitStatsData _stats() {
  HabitRangeStats range(double ratio, String best) => HabitRangeStats(
    completionRatio: ratio,
    bestWeekday: _day(best, 1, 1),
    worstWeekday: _day('mon', 0, 1),
  );

  return HabitStatsData(
    habitId: 1,
    createdAt: DateTime(2026, 1, 1),
    completedCount: 0,
    missedCount: 0,
    currentStreak: 0,
    longestStreak: 0,
    totalAmountCompleted: 0,
    totalDurationCompletedSeconds: 0,
    rangeStats: {
      StatsRange.week: range(0.25, 'tue'),
      StatsRange.month: range(0.5, 'wed'),
      StatsRange.all: range(0.75, 'thu'),
    },
    dailyProgress: const {},
    currentStrength: 0,
    strengthHistory: const [],
    strengthDates: const [],
    actionableInsight: HabitStrengthInsight.stayConsistent,
    strengthDropLast5Days: 0,
    strengthVarianceLast30Days: 0,
  );
}

void main() {
  testWidgets('switching the range changes the shown completion ratio', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ColorProvider(prefs),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: CompletionRatioSection(stats: _stats())),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('25%'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);

    await tester.tap(find.text('30D'));
    await tester.pumpAndSettle();
    expect(find.text('50%'), findsOneWidget);

    await tester.tap(find.text('ALL'));
    await tester.pumpAndSettle();
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
  });
}
