import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/widgets/profile/get_premium_widget.dart';
import 'package:habitt/widgets/profile/leave_feedback_sheet.dart';
import 'package:habitt/widgets/sheets/backup_sheet.dart';
import 'package:tinycolor2/tinycolor2.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileOptions extends StatelessWidget {
  const ProfileOptions({super.key, required this.cp});

  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      color: cp.habitBg,
      child: Column(
        spacing: 10,
        children: [
          GetPremiumWidget(cp: cp),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: cp.field,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: cp.border),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    ProfileOption(
                      cp: cp,
                      text: loc.privacyPolicy,
                      svgPath: 'assets/images/new-svg/privacy-policy.svg',
                      onTap: () async {
                        final privacyUrl = Uri.parse(
                          'https://ashellz.github.io/habitt_v2/privacy.html',
                        );
                        if (await canLaunchUrl(privacyUrl)) {
                          await launchUrl(
                            privacyUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),

                    Divider(color: cp.border, height: 32),
                    ProfileOption(
                      cp: cp,
                      text: loc.termsOfService,
                      svgPath: 'assets/images/new-svg/terms.svg',
                      onTap: () async {
                        final tosUrl = Uri.parse(
                          'https://ashellz.github.io/habitt_v2/tos.html',
                        );
                        if (await canLaunchUrl(tosUrl)) {
                          await launchUrl(
                            tosUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                    Divider(color: cp.border, height: 32),
                    ProfileOption(
                      cp: cp,
                      text: loc.leaveFeedback,
                      svgPath: 'assets/images/new-svg/rate.svg',
                      onTap: () async {
                        await showModalBottomSheet(
                          context: context,
                          backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
                          barrierColor: cp.greyText.darken().withValues(
                            alpha: 0.3,
                          ),
                          isScrollControlled: true,
                          builder: (context) => LeaveFeedbackSheet(),
                        );
                      },
                    ),
                    Divider(color: cp.border, height: 32),
                    ProfileOption(
                      cp: cp,
                      text: loc.backupAndSync,
                      svgPath: 'assets/images/new-svg/backup.svg',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        backgroundColor: cp.isDark ? cp.habitBg : cp.bg,
                        barrierColor: cp.greyText.darken().withValues(
                          alpha: 0.3,
                        ),
                        isScrollControlled: true,
                        builder: (context) => const BackupSheet(),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: cp.field,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: cp.border),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    Text(
                      loc.logOut,
                      style: TextStyle(
                        color: cp.error,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Spacer(),
                    SvgPicture.asset(
                      'assets/images/new-svg/log-out.svg',
                      colorFilter: ColorFilter.mode(cp.error, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  const ProfileOption({
    super.key,
    required this.cp,
    required this.text,
    required this.svgPath,
    this.onTap,
  });

  final ColorProvider cp;
  final String text;
  final String svgPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Row(
          spacing: 12,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: SvgPicture.asset(
                svgPath,
                colorFilter: ColorFilter.mode(
                  cp.lightGreyText,
                  BlendMode.srcIn,
                ),
                fit: BoxFit.contain,
              ),
            ),
            Text(
              text,
              style: TextStyle(
                color: cp.text,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            RotatedBox(
              quarterTurns: 2,
              child: SvgPicture.asset(
                'assets/images/new-svg/back.svg',
                colorFilter: ColorFilter.mode(cp.text, BlendMode.srcIn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
