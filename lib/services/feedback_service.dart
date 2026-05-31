import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackService {
  static const String bugReportTemplate =
      'Name:\nDescription/summary:\nEnvironment/platform:\nVisual proof/screenshot/video:\nSteps to reproduce:\nExpected result vs. actual result:';

  static const String supportEmail = 'ibrsboy32@proton.me';

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
