import 'package:flutter/foundation.dart';
import 'package:habitt/services/ask_budget.dart';
import 'package:habitt/util/date_key.dart';
import 'package:habitt/util/streak_milestones.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts first-time habit completions; written by HabitProvider, read here for
/// the banner's "10 completions" threshold.
const String kTotalCompletionsKey = 'total_habit_completions';

class SupportProvider extends ChangeNotifier {
  static const String _kFirstSeenKey = 'support_first_seen_ms';
  static const String _kDonatedKey = 'support_donated';
  static const String _kAskDayKey = 'support_ask_day';
  static const String _kAskKindKey = 'support_ask_kind';
  static const String _kStreakReachedKey = 'support_streak7_reached';
  static const String _kSheetShownKey = 'support_sheet_last_shown';
  static const String _kBannerDismissalsKey = 'support_banner_dismissals';
  static const String _kBannerNextDayKey = 'support_banner_next_day';

  /// Days of use and completions before the main-page banner first shows.
  static const int bannerMinDaysOfUse = 7;
  static const int bannerMinCompletions = 10;

  /// How long the banner stays away after the 1st, 2nd and 3rd dismissal; every
  /// later dismissal repeats the last.
  static const List<int> bannerDismissDays = [30, 45, 90];

  SupportProvider(
    this._prefs, {
    required bool Function() readSupporter,
    required Future<bool> Function() checkSupporter,
    bool? platformSupportsAsks,
    DateTime Function()? clock,
  }) : _readSupporter = readSupporter,
       _checkSupporter = checkSupporter,
       _platformSupportsAsks = platformSupportsAsks ?? _billingPlatform(),
       _clock = clock ?? DateTime.now {
    if (!_prefs.containsKey(_kFirstSeenKey)) {
      _prefs.setInt(_kFirstSeenKey, _clock().millisecondsSinceEpoch);
    }
    _budget = AskBudget(
      claimedDay: _prefs.getString(_kAskDayKey),
      claimedKind: AskKind.values.asNameMap()[_prefs.getString(_kAskKindKey)],
      clock: _clock,
      onClaim: (day, kind) {
        _prefs.setString(_kAskDayKey, day);
        _prefs.setString(_kAskKindKey, kind.name);
      },
    );
  }

  final SharedPreferences _prefs;
  final bool Function() _readSupporter;
  final Future<bool> Function() _checkSupporter;
  final bool _platformSupportsAsks;
  final DateTime Function() _clock;
  late final AskBudget _budget;

  static bool _billingPlatform() =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// Moment the app was first opened with this feature, "7 days of use" counts
  /// from here (existing users get the grace period after updating).
  DateTime get firstSeen => DateTime.fromMillisecondsSinceEpoch(
    _prefs.getInt(_kFirstSeenKey) ?? _clock().millisecondsSinceEpoch,
  );

  bool get donated => _prefs.getBool(_kDonatedKey) ?? false;

  bool get isSupporter => _readSupporter();

  bool get asksHidden => donated || isSupporter || !_platformSupportsAsks;

  void markDonated() {
    if (donated) return;
    _prefs.setBool(_kDonatedKey, true);
    notifyListeners();
  }

  // checks for subscription or donation status
  Future<void> refreshSupporter() async {
    final before = isSupporter;
    await _checkSupporter();
    if (isSupporter != before) notifyListeners();
  }

  bool get claimedToday => _budget.claimedToday;

  bool get mainBannerAllowed => _budget.mainBannerAllowed;

  // Claims today's budget for an interruptive ask
  bool tryClaimAsk(AskKind kind) {
    final claimed = _budget.tryClaim(kind);
    if (claimed) notifyListeners();
    return claimed;
  }

  // if streak >= 7 then its true
  bool get reviewMilestoneReached =>
      _prefs.getBool(_kStreakReachedKey) ?? false;

  // notes every streak change so it can mark the milestone reached
  void noteStreak(int streak) {
    if (streak < kReviewStreakMilestone || reviewMilestoneReached) return;
    _prefs.setBool(_kStreakReachedKey, true);
  }

  // ─── Support sheet ────────────────────────────────────────

  /// How long after the "free for everyone" sheet was shown before the next
  /// theme pick or backup setup may show it again.
  static const int sheetRepeatDays = 30;

  /// Whether the "free for everyone" sheet should show now: asks are not hidden
  /// and it has never been shown, or last showed [sheetRepeatDays] calendar days
  /// ago. It is user-initiated, so it neither claims nor checks the ask budget.
  bool get sheetDue {
    if (asksHidden) return false;
    final last = DateTime.tryParse(_prefs.getString(_kSheetShownKey) ?? '');
    if (last == null) return true;
    final days = _calendarDaysBetween(last, _clock());
    // a negative count can only come from a clock moved back, do not wait it out
    return days < 0 || days >= sheetRepeatDays;
  }

  void markSheetShown() {
    _prefs.setString(_kSheetShownKey, dateKey(_clock()));
  }

  // ─── Main-page banner ─────────────────────────────────────

  int get completions => _prefs.getInt(kTotalCompletionsKey) ?? 0;

  /// Whether the slim banner after the habit list should show right now. It is
  /// ambient: it never claims the ask budget, it only yields to a claim.
  bool get bannerVisible {
    if (asksHidden || !mainBannerAllowed) return false;
    final today = _clock();
    if (_calendarDaysBetween(firstSeen, today) < bannerMinDaysOfUse) {
      return false;
    }
    if (completions < bannerMinCompletions) return false;

    final nextDay = _prefs.getString(_kBannerNextDayKey);
    if (nextDay == null) return true;
    // A next day further away than the longest wait can only come from a clock
    // that was moved ahead and back, so it is ignored rather than honoured.
    final latest = dateKey(
      DateTime(today.year, today.month, today.day + bannerDismissDays.last),
    );
    if (nextDay.compareTo(latest) > 0) return true;
    return dateKey(today).compareTo(nextDay) >= 0;
  }

  /// The X on the banner: hides it for 30 days, then 45, then 90 (and stays 90).
  void dismissBanner() {
    final dismissals = (_prefs.getInt(_kBannerDismissalsKey) ?? 0) + 1;
    final wait =
        bannerDismissDays[(dismissals - 1).clamp(
          0,
          bannerDismissDays.length - 1,
        )];
    final today = _clock();
    _prefs.setInt(_kBannerDismissalsKey, dismissals);
    _prefs.setString(
      _kBannerNextDayKey,
      dateKey(DateTime(today.year, today.month, today.day + wait)),
    );
    notifyListeners();
  }

  // Whole calendar days from [from] to [to], unaffected by DST (a 23 h day
  // still counts as one).
  static int _calendarDaysBetween(DateTime from, DateTime to) =>
      DateTime.utc(
        to.year,
        to.month,
        to.day,
      ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
}
