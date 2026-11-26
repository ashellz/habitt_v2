// Generates the widget snapshots the watch apps show for the store
// screenshots (docs/watch_app.md, "Store screenshots"). Not a real test: it
// writes marketing/watch_screenshots/fixtures/<lang>/<shot>.json through the
// real WidgetSnapshotBuilder, so names, units and labels are the app's own.
//
//   flutter test tool/store_screenshots/watch_fixtures_test.dart
//
// The snapshots are for today's date: regenerate them on the day you capture.
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/models/habit.dart';
import 'package:habitt/providers/stats_provider.dart';
import 'package:habitt/services/theme_catalog.dart';
import 'package:habitt/services/widget_snapshot_builder.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../test/fixtures/habit_factory.dart';

// ─── Habits ───────────────────────────────────────────

const _languages = ['en', 'de', 'es', 'fr', 'it', 'pt', 'tr', 'bs'];

/// Habit names per language (same order as [_habits]).
const _names = <String, List<String>>{
  'en': ['Make bed', 'Drink water', 'Meditate', 'Read', 'Floss'],
  'de': ['Bett machen', 'Wasser trinken', 'Meditieren', 'Lesen', 'Zahnseide'],
  'es': ['Hacer la cama', 'Beber agua', 'Meditar', 'Leer', 'Hilo dental'],
  'fr': ['Faire son lit', "Boire de l'eau", 'Méditer', 'Lire', 'Fil dentaire'],
  'it': ['Rifare il letto', 'Bere acqua', 'Meditare', 'Leggere', 'Filo interdentale'],
  'pt': ['Fazer a cama', 'Beber água', 'Meditar', 'Ler', 'Fio dental'],
  'tr': ['Yatağı topla', 'Su iç', 'Meditasyon', 'Kitap oku', 'Diş ipi'],
  'bs': ['Namjesti krevet', 'Pij vodu', 'Meditiraj', 'Čitaj', 'Konac za zube'],
};

/// Stable ids, so the capture script can open a habit's screen.
const bedId = 1001, waterId = 1002, meditateId = 1003, readId = 1004, flossId = 1005;

class _Progress {
  const _Progress({this.bed = false, this.water = 0, this.meditate = 0, this.read = 0, this.floss = false});
  final bool bed;
  final int water; // glasses of 6
  final int meditate; // seconds of 600
  final int read; // pages of 10
  final bool floss;
}

/// The shots: the list (one done, one at a third, one not started), the two
/// log screens and Day complete.
const _shots = <String, _Progress>{
  'today': _Progress(bed: true, water: 2),
  'log_amount': _Progress(bed: true, water: 2, read: 6),
  'log_duration': _Progress(bed: true, water: 2, meditate: 360),
  'day_complete': _Progress(bed: true, water: 6, meditate: 600, read: 10, floss: true),
};

List<Habit> _habits(String lang, _Progress p) {
  final n = _names[lang]!;
  Habit make(int id, String name, String emoji, int category,
      {HabitTrackingType? type, int amount = 1, int amountDone = 0, String label = 'times',
      int duration = 0, int durationDone = 0, bool done = false}) {
    final h = buildTestHabit(
      id: id,
      name: name,
      amount: amount,
      amountCompleted: amountDone,
      amountLabel: label,
      duration: duration,
      durationCompleted: durationDone,
      trackingType: type,
      premadeHabitType: null,
    );
    h.categoryId = category;
    h.iconPath = emoji;
    h.trackingType = type; // the constructor infers one when given null
    h.completed = done;
    return h;
  }

  return [
    make(bedId, n[0], '🛏️', WidgetSnapshotBuilder.morning, done: p.bed),
    make(waterId, n[1], '💧', WidgetSnapshotBuilder.morning,
        type: HabitTrackingType.amount, amount: 6, amountDone: p.water, label: 'glasses', done: p.water >= 6),
    make(meditateId, n[2], '🧘', WidgetSnapshotBuilder.morning,
        type: HabitTrackingType.duration, duration: 600, durationDone: p.meditate, done: p.meditate >= 600),
    make(readId, n[3], '📖', WidgetSnapshotBuilder.evening,
        type: HabitTrackingType.amount, amount: 10, amountDone: p.read, label: 'pages', done: p.read >= 10),
    make(flossId, n[4], '🦷', WidgetSnapshotBuilder.evening, done: p.floss),
  ];
}

// ─── Build ────────────────────────────────────────────

void main() {
  test('writes the watch screenshot snapshots', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final out = Directory('marketing/watch_screenshots/fixtures');

    for (final lang in _languages) {
      await initializeDateFormatting(lang == 'bs' ? 'hr' : lang);
      Intl.defaultLocale = lang == 'bs' ? 'hr' : lang;
      for (final shot in _shots.entries) {
        final habits = _habits(lang, shot.value);
        final json = WidgetSnapshotBuilder.build(
          WidgetSnapshotInput(
            now: now,
            todayHabits: habits,
            tomorrowHabits: const [],
            statuses: {
              for (int i = 1; i <= 11; i++) today.subtract(Duration(days: i)): DayCompletionStatus.perfect,
              today: classifyDayStatus(habits),
            },
            dayProgress: const {},
            streak: 11,
            tailMisses: 0,
            loc: lookupAppLocalizations(Locale(lang)),
            localeCode: lang == 'bs' ? 'hr' : lang,
            customSingulars: const {},
            formatTime: (m) => '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}',
            theme: ThemeCatalog.habitt,
          ),
        );
        final file = File('${out.path}/$lang/${shot.key}.json')..createSync(recursive: true);
        file.writeAsStringSync(jsonEncode(json));
      }
    }
  });
}
