import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:habitt/pages/main_pages/profile_page.dart';
import 'package:habitt/providers/color_provider.dart';

class ProfileOptions extends StatelessWidget {
  const ProfileOptions({super.key, required this.cp});

  final ColorProvider cp;

  @override
  Widget build(BuildContext context) {
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
                      text: 'Privacy policy',
                      svgPath: 'assets/images/new-svg/privacy-policy.svg',
                    ),

                    Divider(color: cp.border, height: 32),
                    ProfileOption(
                      cp: cp,
                      text: 'Terms of service',
                      svgPath: 'assets/images/new-svg/terms.svg',
                    ),
                    Divider(color: cp.border, height: 32),
                    ProfileOption(
                      cp: cp,
                      text: 'Rate us',
                      svgPath: 'assets/images/new-svg/rate.svg',
                    ),
                    Divider(color: cp.border, height: 32),
                    ProfileOption(
                      cp: cp,
                      text: 'Backup & Sync',
                      svgPath: 'assets/images/new-svg/backup.svg',
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
                      'Log out',
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
  });

  final ColorProvider cp;
  final String text;
  final String svgPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Row(
        spacing: 12,
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: SvgPicture.asset(
              svgPath,
              colorFilter: ColorFilter.mode(cp.lightGreyText, BlendMode.srcIn),
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
    );
  }
}
