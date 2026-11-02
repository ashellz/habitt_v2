import 'package:habitt/models/premade_habit_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences bool: whether premade habits with a Health metric sync
/// with Health. Absent means the user hasn't decided yet: the first premade
/// Health habit shows the dialog and its answer is stored here. Once set, only
/// the Settings toggle changes it, and the dialog never shows again.
const String kPremadeHealthSyncKey = 'premadeHealthSync';

/// What picking a premade template does about Health sync.
enum PremadeHealthDecision {
  /// The template has no Health metric, nothing to ask.
  notHealthLinked,

  /// Health can't be used here (web/desktop, Health Connect missing, or the
  /// platform doesn't support this metric): open with sync off, no dialog.
  manualOnly,

  /// Never decided: show the in-app dialog (once ever).
  ask,

  /// Setting on: link Health without asking.
  useHealth,

  /// Setting off: open with sync off without asking.
  useManual,
}

/// Decides whether the in-app Health dialog is shown for [template].
///
/// Health being unusable always wins (nothing to sync, nothing to ask, and the
/// setting is left alone). Otherwise the dialog is shown only while
/// [savedSync] is still `null` (never decided).
PremadeHealthDecision decidePremadeHealthPrompt({
  required PremadeHabitTemplate template,
  required bool isAvailable,
  required bool isMetricSupported,
  required bool? savedSync,
}) {
  if (template.defaultHealthMetric == null) {
    return PremadeHealthDecision.notHealthLinked;
  }
  if (!isAvailable || !isMetricSupported) {
    return PremadeHealthDecision.manualOnly;
  }
  if (savedSync == null) return PremadeHealthDecision.ask;
  return savedSync
      ? PremadeHealthDecision.useHealth
      : PremadeHealthDecision.useManual;
}

/// The stored setting, or `null` when the user hasn't decided yet.
Future<bool?> loadPremadeHealthSync() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kPremadeHealthSyncKey);
  } catch (_) {
    return null;
  }
}

Future<void> savePremadeHealthSync(bool value) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPremadeHealthSyncKey, value);
  } catch (_) {
    // worst case the dialog shows once more
  }
}
