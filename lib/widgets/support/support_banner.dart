import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/util/support_navigator.dart';
import 'package:habitt/util/support_thanks.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';

/// Slim, dismissible ask after the habit list on the main page. It is ambient:
/// whether it shows is decided by [SupportProvider.bannerVisible] (7 days of use,
/// 10 completions, not donated or subscribed, dismiss schedule, and no other ask
/// claimed today), and it collapses away when that turns false.
class SupportBanner extends StatelessWidget {
  const SupportBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportProvider>();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child:
          support.bannerVisible
              ? _BannerCard(
                onDonated: () {
                  showDonationThanks(context);
                  support.markDonated();
                },
              )
              : const SizedBox(width: double.infinity),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.onDonated});

  final VoidCallback onDonated;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final support = context.read<SupportProvider>();
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 8),
        decoration: ShapeDecoration(
          color: cp.widget,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: cp.border),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Message & dismiss ────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      loc.supportBannerText,
                      style: TextStyle(
                        color: cp.greyText,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: loc.supportBannerDismiss,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: support.dismissBanner,
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/new-svg/close.svg',
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            cp.lightGreyText,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ─── Actions ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 4),
              child: NewDefaultButton.primary(
                height: 44,
                label: loc.supportSeeWays,
                onPressed: () => openSupportPage(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDonated,
                child: SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      loc.supportAlreadyDonated,
                      style: TextStyle(
                        color: cp.greyText,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: cp.greyText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
