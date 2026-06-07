import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackService {
  static const String bugReportTemplate =
      'Name:\nDescription/summary:\nEnvironment/platform:\nVisual proof/screenshot/video:\nSteps to reproduce:\nExpected result vs. actual result:';

  static const String supportEmail = 'ibrsboy32@proton.me';

  static const String _reviewLastRequestedKey = 'review_last_requested_ms';

  // Silently shows the native review dialog when engagement thresholds are met.
  // Safe to call on every completion — guards ensure it only fires once per 90 days.
  static Future<void> maybeRequestReview({
    required int totalCompletions,
    required int maxStreak,
  }) async {
    if (totalCompletions < 10 || maxStreak < 3) return;

    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_reviewLastRequestedKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const ninetyDays = 90 * 24 * 60 * 60 * 1000;

    if (lastMs != 0 && (now - lastMs) < ninetyDays) return;

    final inAppReview = InAppReview.instance;
    if (!await inAppReview.isAvailable()) return;

    await inAppReview.requestReview();
    await prefs.setInt(_reviewLastRequestedKey, now);
  }

  static Future<void> rateUs() async {
    final InAppReview inAppReview = InAppReview.instance;

    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.openStoreListing(appStoreId: '6745617462');
      } else {
        await _launchStorePage();
      }
    } catch (_) {
      await _launchStorePage();
    }
  }

  static Future<void> _launchStorePage() async {
    final Uri androidUrl = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.shellz.habitt',
    );
    final Uri iosUrl = Uri.parse(
      'https://apps.apple.com/us/app/habitt-your-habit-tracker/id6745617462',
    );

    final Uri url =
        defaultTargetPlatform == TargetPlatform.android ? androidUrl : iosUrl;
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> sendBugReport() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': 'Bug Report', 'body': bugReportTemplate},
    );

    if (!await launchUrl(uri)) {
      throw Exception('Could not launch email client');
    }
  }
}
