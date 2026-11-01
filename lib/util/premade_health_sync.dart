import 'package:habitt/models/premade_habit_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences bool, set once the user accepts the "use Health?" dialog
/// shown when picking a premade habit. See `docs/health_sync.md`.
const String kPremadeHealthSyncAcceptedKey = 'premadeHealthSyncAccepted';

/// What picking a premade template does about Health sync.
enum PremadeHealthDecision {
  /// The template has no Health metric, nothing to ask.
  notHealthLinked,

  /// Health can't be used here (web/desktop, Health Connect missing, or the
  /// platform doesn't support this metric): open the sheet with sync off,
  /// without asking.
  manualOnly,

  /// Show the in-app dialog first.
  ask,

  /// The user already accepted before and access is still granted: link
  /// Health without asking again.
  syncWithoutAsking,
}

/// Decides whether the in-app Health dialog is shown for [template].
///
/// The dialog is skipped only when Health is unusable, or when the user has
/// accepted it before **and** the OS permission is still granted. If they
/// accepted but access was since revoked (or never granted), they are asked
/// again, since syncing would silently do nothing otherwise. A user who
/// declined is asked again next time: declining is per habit, not a setting.
PremadeHealthDecision decidePremadeHealthPrompt({
  required PremadeHabitTemplate template,
  required bool isAvailable,
  required bool isMetricSupported,
  required bool permissionGranted,
  required bool previouslyAccepted,
}) {
  if (template.defaultHealthMetric == null) {
    return PremadeHealthDecision.notHealthLinked;
  }
  if (!isAvailable || !isMetricSupported) {
    return PremadeHealthDecision.manualOnly;
  }
  if (permissionGranted && previouslyAccepted) {
    return PremadeHealthDecision.syncWithoutAsking;
  }
  return PremadeHealthDecision.ask;
}

Future<bool> loadPremadeHealthSyncAccepted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kPremadeHealthSyncAcceptedKey) ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> savePremadeHealthSyncAccepted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPremadeHealthSyncAcceptedKey, true);
  } catch (_) {
    // worst case the dialog shows once more
  }
}
