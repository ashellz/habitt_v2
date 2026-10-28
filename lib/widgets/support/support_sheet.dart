import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/util/support_navigator.dart';
import 'package:habitt/util/support_thanks.dart';
import 'package:habitt/widgets/default/new_default_button.dart';
import 'package:habitt/widgets/default/new_default_dialog.dart';
import 'package:provider/provider.dart';

/// The sheet shown when a user picks a new theme or opens cloud backup setup, at
/// most once every 30 days. Both are free for everyone, so it only says so and
/// leaves the choice to them. Shown through [maybeShowSupportSheet].
class SupportSheet extends StatelessWidget {
  const SupportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final loc = AppLocalizations.of(context)!;

    return NewDefaultDialog(
      title: loc.supportSheetTitle,
      desc: loc.supportSheetDesc,
      // the actions are stacked in the body instead of the side-by-side footer
      overrideDefaultButtons: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          NewDefaultButton.primary(
            label: loc.supportSeeWays,
            onPressed: () => openSupportPage(context, popFirst: true),
          ),
          NewDefaultButton.secondary(
            label: loc.supportNotNow,
            onPressed: () => Navigator.pop(context),
          ),
          // ─── Already donated ──────────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showDonationThanks(context);
              context.read<SupportProvider>().markDonated();
              Navigator.pop(context);
            },
            child: SizedBox(
              height: 36,
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
    );
  }
}
