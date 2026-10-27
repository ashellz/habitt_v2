import 'package:flutter/foundation.dart';
import 'package:habitt/services/ask_budget.dart';
import 'package:habitt/util/streak_milestones.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupportProvider extends ChangeNotifier {
  static const String _kFirstSeenKey = 'support_first_seen_ms';
  static const String _kDonatedKey = 'support_donated';
  static const String _kAskDayKey = 'support_ask_day';
  static const String _kAskKindKey = 'support_ask_kind';
  static const String _kStreakReachedKey = 'support_streak7_reached';

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
}
