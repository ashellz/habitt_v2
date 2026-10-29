/// The release whose "What's new" sheet the app carries. Stored as the user's
/// `lastSeenVersion` once the sheet is dismissed, so it shows once. Bump it
/// (and the sheet's copy) when a later release gets its own sheet.
const String kWhatsNewVersion = '2.5.0';

/// Users who joined on or before this day are existing users who see the
/// sheet; anyone who joined on or after it is new and never does. Set it to a
/// day before the release goes live.
final DateTime kWhatsNewCutoff = DateTime(2026, 11, 10);

/// Whether the "What's new" sheet is due: the user joined before [cutoff]
/// (compared by calendar day, the time of day is ignored) and has not yet seen
/// the sheet for [currentVersion].
bool shouldShowWhatsNew({
  required DateTime dateJoined,
  required String? lastSeenVersion,
  String currentVersion = kWhatsNewVersion,
  DateTime? cutoff,
}) {
  final cut = cutoff ?? kWhatsNewCutoff;
  final joined = DateTime(dateJoined.year, dateJoined.month, dateJoined.day);
  final cutDay = DateTime(cut.year, cut.month, cut.day);
  return joined.isBefore(cutDay) && lastSeenVersion != currentVersion;
}
