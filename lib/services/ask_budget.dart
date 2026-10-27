import 'package:habitt/util/date_key.dart';

// kinds are: native review dialog and a banner on streak celebration milestones
enum AskKind { review, milestoneBanner }

/// Which ask gets a streak moment when several are possible, first wins. The
/// review goes first; the support card then first shows up at the 30-day
/// milestone (or at 7 for users the review's 90-day guard already covers).
const List<AskKind> kMomentAskPriority = [
  AskKind.review,
  AskKind.milestoneBanner,
];

/// At most one unprompted ask per calendar day. Pure logic: the clock and
/// persistence are injected so the rules can be unit-tested.
class AskBudget {
  AskBudget({
    String? claimedDay,
    AskKind? claimedKind,
    DateTime Function()? clock,
    this.onClaim,
  }) : _claimedDay = claimedDay,
       _claimedKind = claimedKind,
       _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final void Function(String day, AskKind kind)? onClaim;

  String? _claimedDay;
  AskKind? _claimedKind;

  /// A claim from another day (including a future one left by a clock that was
  /// moved ahead and back) does not count.
  bool get claimedToday => _claimedDay == dateKey(_clock());

  /// The ambient main-page banner may show only while no interruptive ask has
  /// claimed today.
  bool get mainBannerAllowed => !claimedToday;

  /// Claims today's budget for [kind]. Succeeds when nothing claimed today, and
  /// again for the same kind so re-evaluating one ask is harmless.
  bool tryClaim(AskKind kind) {
    if (claimedToday) return _claimedKind == kind;
    final today = dateKey(_clock());
    _claimedDay = today;
    _claimedKind = kind;
    onClaim?.call(today, kind);
    return true;
  }
}

/// Picks the ask for a streak moment from [possible], honouring [priority].
/// Null when today's budget is already spent or nothing is possible.
AskKind? planMomentAsk({
  required bool budgetFree,
  required Set<AskKind> possible,
  List<AskKind> priority = kMomentAskPriority,
}) {
  if (!budgetFree) return null;
  for (final kind in priority) {
    if (possible.contains(kind)) return kind;
  }
  return null;
}
