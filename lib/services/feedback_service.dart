import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackService {
  static const String bugReportTemplate =
      'Name:\nDescription/summary:\nEnvironment/platform:\nVisual proof/screenshot/video:\nSteps to reproduce:\nExpected result vs. actual result:';

  static const String habitRequestTemplate =
      'Habit name:\nWhy it\'d be useful:\nSuggested tracking (amount/duration/count):\nPlatform:';

  static const String supportEmail = 'ibrsboy32@proton.me';

  static const String _reviewLastRequestedKey = 'review_last_requested_ms';

  // Whether the native review dialog can be requested right now: the 90-day
  // guard has passed and the platform offers it. Has no side effects, so the
  // daily ask budget is only spent on a review that can actually show.
  static Future<bool> canRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_reviewLastRequestedKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const ninetyDays = 90 * 24 * 60 * 60 * 1000;

    if (lastMs != 0 && (now - lastMs) < ninetyDays) return false;

    try {
      return await InAppReview.instance.isAvailable();
    } catch (_) {
      return false;
    }
  }

  // Shows the native review dialog and starts the 90-day guard. Callers decide
  // when (a streak milestone, see runStreakMoment) after canRequestReview.
  static Future<void> requestReview() async {
    await InAppReview.instance.requestReview();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _reviewLastRequestedKey,
      DateTime.now().millisecondsSinceEpoch,
    );
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

  static Future<void> sendHabitRequest() async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'Habit Request',
        'body': habitRequestTemplate,
      },
    );

    if (!await launchUrl(uri)) {
      throw Exception('Could not launch email client');
    }
  }
}
