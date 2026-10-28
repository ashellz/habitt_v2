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

  group('main-page banner', () {
    late SupportProvider provider;

    // a user who joined on `now`, then `days` calendar days passed
    void useFor(int days, {int completions = 10}) {
      prefs.setInt(kTotalCompletionsKey, completions);
      provider = build();
      now = DateTime(now.year, now.month, now.day + days, 9);
    }

    test('is hidden for the first 7 days of use', () {
      useFor(6);
      expect(provider.bannerVisible, isFalse);
    });

    test('shows once 7 days and 10 completions are reached', () {
      useFor(7);
      expect(provider.bannerVisible, isTrue);
    });

    test('counts calendar days, not 24 hour spans', () {
      now = DateTime(2026, 11, 3, 23, 30);
      prefs.setInt(kTotalCompletionsKey, 10);
      provider = build();
      now = DateTime(2026, 11, 10, 0, 10);
      expect(provider.bannerVisible, isTrue);
    });

    test('needs 10 completions', () {
      useFor(30, completions: 9);
      expect(provider.bannerVisible, isFalse);
    });

    test('is hidden for donors and subscribers', () {
      useFor(10);
      supporter = true;
      expect(provider.bannerVisible, isFalse);

      supporter = false;
      expect(provider.bannerVisible, isTrue);
      provider.markDonated();
      expect(provider.bannerVisible, isFalse);
    });

    test('yields to an ask that claimed today and returns tomorrow', () {
      useFor(10);
      provider.tryClaimAsk(AskKind.review);
      expect(provider.bannerVisible, isFalse);

      now = DateTime(now.year, now.month, now.day + 1, 9);
      expect(provider.bannerVisible, isTrue);
    });

    test('never claims the ask budget itself', () {
      useFor(10);
      expect(provider.bannerVisible, isTrue);
      expect(provider.claimedToday, isFalse);
    });

    test('dismissing waits 30, then 45, then 90, then 90 days', () {
      useFor(10);
      for (final wait in [30, 45, 90, 90]) {
        expect(provider.bannerVisible, isTrue);
        provider.dismissBanner();
        expect(provider.bannerVisible, isFalse);

        final dismissedOn = now;
        now = DateTime(
          dismissedOn.year,
          dismissedOn.month,
          dismissedOn.day + wait - 1,
        );
        expect(provider.bannerVisible, isFalse, reason: 'day ${wait - 1}');

        now = DateTime(
          dismissedOn.year,
          dismissedOn.month,
          dismissedOn.day + wait,
        );
        expect(provider.bannerVisible, isTrue, reason: 'day $wait');
      }
    });

    test('dismissing notifies and survives a restart', () {
      useFor(10);
      var notified = 0;
      provider.addListener(() => notified++);

      provider.dismissBanner();
      expect(notified, 1);
      expect(build().bannerVisible, isFalse);
    });

    test('ignores a next day pushed far ahead by a moved clock', () {
      useFor(10);
      prefs.setString('support_banner_next_day', '2030-01-01');
      expect(provider.bannerVisible, isTrue);
    });
  });

  group('support sheet', () {
    test('is due for a regular user who has never seen it', () {
      expect(build().sheetDue, isTrue);
    });

    test('is not due again right after it was shown, even after a restart', () {
      build().markSheetShown();
      expect(build().sheetDue, isFalse);
    });

    test('is due again after 30 calendar days, not before', () {
      build().markSheetShown();

      now = DateTime(2026, 12, 2, 23, 59); // 29 days later
      expect(build().sheetDue, isFalse);

      now = DateTime(2026, 12, 3, 0, 1); // 30 days later
      expect(build().sheetDue, isTrue);
    });

    test('waits out the full period again after being shown a second time', () {
      build().markSheetShown();
      now = DateTime(2026, 12, 3, 9);
      build().markSheetShown();

      now = DateTime(2027, 1, 1, 9); // 29 days after the second showing
      expect(build().sheetDue, isFalse);
      now = DateTime(2027, 1, 2, 9);
      expect(build().sheetDue, isTrue);
    });

    test('a clock moved back does not hide it for months', () {
      now = DateTime(2027, 6, 1);
      build().markSheetShown();

      now = DateTime(2026, 11, 3);
      expect(build().sheetDue, isTrue);
    });

    test('is never due for donors, subscribers or unsupported platforms', () {
      supporter = true;
      expect(build().sheetDue, isFalse);

      supporter = false;
      build().markDonated();
      now = DateTime(2030, 1, 1);
      expect(build().sheetDue, isFalse);

      expect(build(platformSupportsAsks: false).sheetDue, isFalse);
    });

    test('is due again after a long wait for a user who was asked before', () {
      build().markSheetShown();
      now = DateTime(2027, 6, 1);
      expect(build().sheetDue, isTrue);
    });

    test(
      'does not touch the ask budget, and a claimed budget does not stop it',
      () {
        final provider = build();
        provider.markSheetShown();
        expect(provider.claimedToday, isFalse);

        prefs.remove('support_sheet_last_shown');
        final claimed = build()..tryClaimAsk(AskKind.review);
        expect(claimed.sheetDue, isTrue);
      },
    );
  });
}
