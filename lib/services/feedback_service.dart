import 'package:flutter_email_sender/flutter_email_sender.dart';
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
        await inAppReview.requestReview();
      } else {
        // Fallback to store links if in-app review is not available
        await _launchStorePage();
      }
    } catch (_) {
      // If in-app review fails, try launching store page
      await _launchStorePage();
    }
  }

  static Future<void> _launchStorePage() async {
    // Try to open the app store link
    // These URLs should be replaced with actual app store URLs
    final Uri androidUrl = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.shellz.habitt&hl=en-US&ah=pOP1nFvk-kYT2fbDhv9cYBHNbG4',
    );
    final Uri iosUrl = Uri.parse(
      'https://apps.apple.com/app/id6745617462',
    ); // Replace with actual app ID

    try {
      if (await canLaunchUrl(androidUrl)) {
        await launchUrl(androidUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(iosUrl)) {
        await launchUrl(iosUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      rethrow;
    }
  }

  static Future<void> sendBugReport() async {
    final Email email = Email(
      body: bugReportTemplate,
      subject: 'Bug Report',
      recipients: [supportEmail],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (_) {
      rethrow;
    }
  }
}
