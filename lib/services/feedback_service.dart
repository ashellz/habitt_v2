import 'package:flutter/foundation.dart';
import 'package:habitt/models/backup_metadata.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackService {
  static String bugReportTemplate({
    required String version,
    required String phone,
    required String os,
  }) =>
      'Thanks for helping make Habitt better! 🐞\n'
      '\n'
      'Tips for a great bug report:\n'
      '• Be specific: what did you do, and what went wrong?\n'
      '• List the steps so we can reproduce it.\n'
      '• Add a screenshot or screen recording if you can.\n'
      '• Delete these tips before sending.\n'
      '\n'
      '──────────\n'
      '\n'
      'Version: $version\n'
      'Phone: $phone\n'
      'OS: $os\n'
      'Bug:\n'
      '\n'
      '\n';

  static const String featureRequestTemplate =
      'Thanks for sharing your idea! 💡\n'
      '\n'
      'Tips for a great feature request:\n'
      '• Describe the problem you want solved, not just the solution.\n'
      '• Explain how you would use it day to day.\n'
      '• Sketches or examples from other apps are welcome.\n'
      '• Delete these tips before sending.\n'
      '\n'
      '──────────\n'
      '\n'
      'Feature idea:\n'
      '\n'
      '\n';

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

  // Built by hand because Uri(queryParameters:) form-encodes spaces as '+',
  // which mail apps show literally instead of as spaces.
  static Future<void> _sendMail(String subject, String body) async {
    final Uri uri = Uri.parse(
      'mailto:$supportEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    if (!await launchUrl(uri)) {
      throw Exception('Could not launch email client');
    }
  }

  static Future<void> sendBugReport() async {
    var version = 'unknown';
    var phone = 'unknown';
    var os = 'unknown';

    try {
      final package = await PackageInfo.fromPlatform();
      version = '${package.version} (${package.buildNumber})';
    } catch (_) {}

    try {
      final device = await DeviceIdentity.deviceInfo();
      final manufacturer = device['manufacturer'];
      final model = device['model'] ?? 'unknown';
      phone = manufacturer == null ? model : '$manufacturer $model';
      os = device['os'] ?? 'unknown';
    } catch (_) {}

    await _sendMail(
      'Bug Report',
      bugReportTemplate(version: version, phone: phone, os: os),
    );
  }

  static Future<void> sendFeatureRequest() =>
      _sendMail('Feature Request', featureRequestTemplate);

  static Future<void> sendHabitRequest() =>
      _sendMail('Habit Request', habitRequestTemplate);
}
