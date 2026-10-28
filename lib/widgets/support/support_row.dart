import 'package:flutter/material.dart';
import 'package:habitt/l10n/app_localizations.dart';
import 'package:habitt/providers/color_provider.dart';
import 'package:habitt/providers/support_provider.dart';
import 'package:habitt/util/support_navigator.dart';
import 'package:provider/provider.dart';

/// The small permanent "Support Habitt" row on the theme picker and the backup
/// sheet. It is quiet on purpose: it never pops anything up, it only opens the
/// support page, and it disappears for donors and subscribers.
class SupportRow extends StatelessWidget {
  const SupportRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ColorProvider>();
    final hidden = context.select<SupportProvider, bool>((s) => s.asksHidden);
    final loc = AppLocalizations.of(context)!;

    if (hidden) return const SizedBox.shrink();

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openSupportPage(context),
        child: SizedBox(
          height: 44,
          child: Row(
            spacing: 10,
            children: [
              Image.asset(
                'assets/images/widget-images/love-bubble.png',
                width: 24,
                height: 24,
              ),
              Expanded(
                child: Text(
                  loc.supportHabittRow,
                  style: TextStyle(color: cp.greyText, fontSize: 15),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: cp.lightGreyText),
            ],
          ),
        ),
      ),
    );
  }
}
