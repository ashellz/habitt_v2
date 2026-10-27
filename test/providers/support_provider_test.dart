import 'package:flutter_test/flutter_test.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/services/ask_budget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late DateTime now;
  var supporter = false;
  // what the billing check will find; applying it updates `supporter` the way
  // BillingService.checkHasPro does for BillingService.hasPro
  var subscriptionActive = false;

  SupportProvider build({bool platformSupportsAsks = true}) => SupportProvider(
    prefs,
    readSupporter: () => supporter,
    checkSupporter: () async {
      supporter = subscriptionActive;
      return supporter;
    },
    platformSupportsAsks: platformSupportsAsks,
    clock: () => now,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 11, 3, 9);
    supporter = false;
    subscriptionActive = false;
  });

  group('first seen', () {
    test('is stamped once and kept across restarts', () {
      final first = build();
      expect(first.firstSeen, now);

      now = DateTime(2026, 12, 1);
      expect(build().firstSeen, DateTime(2026, 11, 3, 9));
    });
  });

  group('asksHidden', () {
    test('is false for a regular user', () {
      expect(build().asksHidden, isFalse);
    });

    test('hides for subscribers', () {
      supporter = true;
      expect(build().asksHidden, isTrue);
    });

    test('hides for donors, forever', () {
      build().markDonated();
      expect(build().asksHidden, isTrue);
    });

    test('hides where the support page cannot work', () {
      expect(build(platformSupportsAsks: false).asksHidden, isTrue);
    });

    test('markDonated notifies once and persists', () {
      final provider = build();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.markDonated();
      provider.markDonated();

      expect(notified, 1);
      expect(provider.donated, isTrue);
      expect(build().donated, isTrue);
    });

    test('refreshSupporter notifies when the subscription changed', () async {
      final provider = build();
      var notified = 0;
      provider.addListener(() => notified++);

      await provider.refreshSupporter();
      expect(notified, 0);

      subscriptionActive = true;
      await provider.refreshSupporter();
      expect(notified, 1);
      expect(provider.asksHidden, isTrue);
    });
  });

  group('ask budget', () {
    test('a claim persists across restarts and blocks other asks', () {
      expect(build().tryClaimAsk(AskKind.milestoneBanner), isTrue);

      final restarted = build();
      expect(restarted.claimedToday, isTrue);
      expect(restarted.mainBannerAllowed, isFalse);
      expect(restarted.tryClaimAsk(AskKind.review), isFalse);
    });

    test('a claim notifies so the ambient banner can hide', () {
      final provider = build();
      var notified = 0;
      provider.addListener(() => notified++);

      provider.tryClaimAsk(AskKind.review);
      expect(notified, 1);

      provider.tryClaimAsk(AskKind.milestoneBanner);
      expect(notified, 1);
    });

    test('is free again the next day', () {
      build().tryClaimAsk(AskKind.review);

      now = DateTime(2026, 11, 4, 8);
      final nextDay = build();
      expect(nextDay.claimedToday, isFalse);
      expect(nextDay.mainBannerAllowed, isTrue);
    });
  });

  group('review milestone', () {
    test('is not reached below 7', () {
      final provider = build()..noteStreak(6);
      expect(provider.reviewMilestoneReached, isFalse);
    });

    test('is reached at 7 and stays reached when the streak breaks', () {
      build().noteStreak(7);
      final restarted = build()..noteStreak(0);
      expect(restarted.reviewMilestoneReached, isTrue);
    });

    test('is reached by a streak that jumps past 7', () {
      final provider = build()..noteStreak(12);
      expect(provider.reviewMilestoneReached, isTrue);
    });
  });
}
