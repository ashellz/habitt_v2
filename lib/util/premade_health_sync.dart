import 'package:habitt/models/premade_habit_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences string holding the user's standing answer to the "use
/// Health?" dialog shown for premade habits. Absent means "ask".
const String kPremadeHealthSyncChoiceKey = 'premadeHealthSyncChoice';

/// The user's standing answer for premade Health habits. Asked once; the
/// answer is reused until it is changed in Settings.
enum PremadeHealthChoice { ask, health, manual }

/// What picking a premade template does about Health sync.
enum PremadeHealthDecision {
  /// The template has no Health metric, nothing to ask.
  notHealthLinked,

  /// Health can't be used here (web/desktop, Health Connect missing, or the
  /// platform doesn't support this metric): open with sync off, no dialog.
  manualOnly,

  /// No standing answer yet: show the in-app dialog.
  ask,

  /// Standing answer "Health": link it without asking.
  useHealth,

  /// Standing answer "manual": open with sync off without asking.
  useManual,
}

/// Decides whether the in-app Health dialog is shown for [template].
///
/// Health being unusable always wins (nothing to sync, nothing to ask, and the
/// saved answer is left alone). Otherwise the dialog is shown only while
/// [savedChoice] is still [PremadeHealthChoice.ask].
PremadeHealthDecision decidePremadeHealthPrompt({
  required PremadeHabitTemplate template,
  required bool isAvailable,
  required bool isMetricSupported,
  required PremadeHealthChoice savedChoice,
}) {
  if (template.defaultHealthMetric == null) {
    return PremadeHealthDecision.notHealthLinked;
  }
  if (!isAvailable || !isMetricSupported) {
    return PremadeHealthDecision.manualOnly;
  }
  switch (savedChoice) {
    case PremadeHealthChoice.ask:
      return PremadeHealthDecision.ask;
    case PremadeHealthChoice.health:
      return PremadeHealthDecision.useHealth;
    case PremadeHealthChoice.manual:
      return PremadeHealthDecision.useManual;
  }
}

Future<PremadeHealthChoice> loadPremadeHealthChoice() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(kPremadeHealthSyncChoiceKey);
    return PremadeHealthChoice.values.firstWhere(
      (c) => c.name == name,
      orElse: () => PremadeHealthChoice.ask,
    );
  } catch (_) {
    return PremadeHealthChoice.ask;
  }
}

Future<void> savePremadeHealthChoice(PremadeHealthChoice choice) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (choice == PremadeHealthChoice.ask) {
      await prefs.remove(kPremadeHealthSyncChoiceKey);
    } else {
      await prefs.setString(kPremadeHealthSyncChoiceKey, choice.name);
    }
  } catch (_) {
    // worst case the dialog shows once more
  }
}
