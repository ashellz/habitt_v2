import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/services/ask_budget.dart';

void main() {
  late DateTime now;
  late List<(String, AskKind)> claims;

  AskBudget budget({String? day, AskKind? kind}) => AskBudget(
    claimedDay: day,
    claimedKind: kind,
    clock: () => now,
    onClaim: (d, k) => claims.add((d, k)),
  );

  setUp(() {
    now = DateTime(2026, 11, 3, 9);
    claims = [];
  });

  group('AskBudget', () {
    test('a fresh budget is free and lets the banner show', () {
      final b = budget();
      expect(b.claimedToday, isFalse);
      expect(b.mainBannerAllowed, isTrue);
    });

    test('the first ask claims the day and reports it', () {
      final b = budget();
      expect(b.tryClaim(AskKind.milestoneBanner), isTrue);
      expect(b.claimedToday, isTrue);
      expect(claims, [('2026-11-03', AskKind.milestoneBanner)]);
    });

    test('a different ask the same day is blocked', () {
      final b = budget()..tryClaim(AskKind.milestoneBanner);
      expect(b.tryClaim(AskKind.review), isFalse);
      expect(claims, hasLength(1));
    });

    test('the review never shares a day with another ask', () {
      final b = budget()..tryClaim(AskKind.review);
      expect(b.tryClaim(AskKind.milestoneBanner), isFalse);
    });

    test('claiming the same kind again is harmless and writes nothing', () {
      final b = budget()..tryClaim(AskKind.review);
      expect(b.tryClaim(AskKind.review), isTrue);
      expect(claims, hasLength(1));
    });

    test('an interruptive claim hides the ambient banner for the day', () {
      final b = budget();
      expect(b.mainBannerAllowed, isTrue);
      b.tryClaim(AskKind.review);
      expect(b.mainBannerAllowed, isFalse);
    });

    test('the next calendar day starts free again', () {
      final b = budget()..tryClaim(AskKind.review);
      now = DateTime(2026, 11, 4, 0, 5);
      expect(b.claimedToday, isFalse);
      expect(b.tryClaim(AskKind.milestoneBanner), isTrue);
    });

    test('rolls over at midnight, not after 24 hours', () {
      now = DateTime(2026, 11, 3, 23, 59);
      final b = budget()..tryClaim(AskKind.review);
      now = DateTime(2026, 11, 4, 0, 1);
      expect(b.claimedToday, isFalse);
    });

    test('restores a claim persisted earlier today', () {
      final b = budget(day: '2026-11-03', kind: AskKind.review);
      expect(b.claimedToday, isTrue);
      expect(b.tryClaim(AskKind.milestoneBanner), isFalse);
    });

    test('ignores a stale or future claim left by a moved clock', () {
      expect(budget(day: '2026-11-01', kind: AskKind.review).claimedToday,
          isFalse);
      expect(budget(day: '2027-01-01', kind: AskKind.review).claimedToday,
          isFalse);
    });
  });

  group('planMomentAsk', () {
    test('review beats the milestone card by default', () {
      expect(
        planMomentAsk(
          budgetFree: true,
          possible: {AskKind.milestoneBanner, AskKind.review},
        ),
        AskKind.review,
      );
    });

    test('falls back to the milestone card when the review is not possible', () {
      expect(
        planMomentAsk(budgetFree: true, possible: {AskKind.milestoneBanner}),
        AskKind.milestoneBanner,
      );
    });

    test('the priority can be flipped', () {
      expect(
        planMomentAsk(
          budgetFree: true,
          possible: {AskKind.milestoneBanner, AskKind.review},
          priority: const [AskKind.milestoneBanner, AskKind.review],
        ),
        AskKind.milestoneBanner,
      );
    });

    test('nothing when the budget is spent or nothing is possible', () {
      expect(
        planMomentAsk(budgetFree: false, possible: {AskKind.review}),
        isNull,
      );
      expect(planMomentAsk(budgetFree: true, possible: {}), isNull);
    });
  });
}
