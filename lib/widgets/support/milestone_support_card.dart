import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/util/support_navigator.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:provider/provider.dart';

/// The support ask inside the streak celebration at the 7- and 30-day
/// milestones. Deliberately unlike the main-page banner: a warm, streak-orange
/// card with a heart instead of a neutral list card. It adds no animation of its
/// own, and collapses if the user says they already donated.
class MilestoneSupportCard extends StatelessWidget {
  const MilestoneSupportCard({super.key, required this.onDonated});

  final VoidCallback onDonated;

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final hidden = context.select<SupportProvider, bool>((s) => s.asksHidden);
    final loc = AppLocalizations.of(context)!;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child:
          hidden
              ? const SizedBox(width: double.infinity)
              : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: cp.orange100,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: cp.orange200),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    // ─── Message ──────────────────────────────────
                    Row(
                      spacing: 12,
                      children: [
                        Image.asset(
                          'assets/images/widget-images/love-bubble.png',
                          width: 40,
                          height: 40,
                        ),
                        Expanded(
                          child: Text(
                            loc.supportMilestoneText,
                            style: TextStyle(
                              color: cp.text,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // ─── Actions ──────────────────────────────────
                    NewDefaultButton(
                      height: 44,
                      color: cp.orange300,
                      textColor: cp.bg,
                      label: loc.supportSeeWays,
                      onPressed: () => openSupportPage(context, popFirst: true),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDonated,
                      child: SizedBox(
                        height: 28,
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
                  ],
                ),
              ),
    );
  }
}
